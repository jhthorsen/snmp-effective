package SNMP::Effective;

=head1 NAME

SNMP::Effective - An effective SNMP-information-gathering module

=head1 VERSION

This document refers to version 1.06 of SNMP::Effective.

=head1 SYNOPSIS

 use SNMP::Effective;
 
 my $snmp = SNMP::Effective->new(
     max_sessions   => $NUM_POLLERS,
     master_timeout => $TIMEOUT_SECONDS,
 );
 
 $snmp->add(
     dest_host => $ip,
     callback  => sub { store_data() },
     get       => [ '1.3.6.1.2.1.1.3.0', 'sysDescr' ],
 );
 # lather, rinse, repeat
 
 # retrieve data from all hosts
 $snmp->execute;

=head1 DESCRIPTION

This module collects information, over SNMP, from many hosts and many OIDs,
really fast.

It is a wrapper around the facilities of C<SNMP.pm>, which is the Perl
interface to the C libraries in the C<SNMP> package. Advantages of using
this module include:

=over 4

=item Simple configuration

The data structures required by C<SNMP> are complex to set up before
polling, and parse for results afterwards. This module provides a simpler
interface to that configuration by accepting just a list of SNMP OIDs or leaf
names.

=item Parallel execution

Many users are not aware that C<SNMP> can poll devices asynchronously
using a callback system. By specifying your callback routine as in the
L</"SYNOPSIS"> section above, many network devices can be polled in parallel,
making operations far quicker. Note that this does not use threads.

=item It's fast

To give one example, C<SNMP::Effective> can walk, say, eight indexed OIDs
(port status, errors, traffic, etc) for around 300 devices (that's 8500 ports)
in under 30 seconds. Storage of that data might take an additional 10 seconds
(depending on whether it's to RAM or disk). This makes polling/monitoring your
network every five minutes (or less) no problem at all.

=back

The interface to this module is simple, with few options. The sections below
detail everything you need to know.

=head1 METHODS ARGUMENTS

The method arguments are very flexible. Any of the below acts as the same:

 $obj->method(MyKey   => $value);
 $obj->method(my_key  => $value);
 $obj->method(My_Key  => $value);
 $obj->method(mYK__EY => $value);

=cut

use warnings;
use strict;
use SNMP;
use SNMP::Effective::Dispatch;
use SNMP::Effective::Host;
use SNMP::Effective::HostList;
use SNMP::Effective::VarList;
use SNMP::Effective::Logger;
use Time::HiRes qw/usleep/;
use POSIX qw(:errno_h);

our $VERSION = '1.06';
our @ISA     = qw/SNMP::Effective::Dispatch/;
our %SNMPARG = (
    Version   => '2c',
    Community => 'public',
    Timeout   => 1e6,
    Retries   => 2
);

=head1 OBJECT ATTRIBUTES

=head2 C<master_timeout>

 Get/Set the master timeout

=head2 C<max_sessions>

 Get/Set the number of max session

=head2 C<log>

This returns the Log4perl object that is used for logging:

 $self->log->warn("log this message!");

=head2 C<hostlist>
 
 Returns a list containing all the hosts.

=head2 C<arg>

 Returns a hash with the default args

=head2 C<callback>

 Returns a ref to the default callback sub-routine.

=cut

BEGIN {
    no strict 'refs'; ## no critic
    my %sub2key = qw/
                      max_sessions    maxsessions
                      master_timeout  mastertimeout
                      _varlist        _varlist
                      hostlist        _hostlist
                      arg             _arg
                      callback        _callback
                      log             _logger
                  /;

    for my $subname (keys %sub2key) {
        *$subname = sub {
            my($self, $set)               = @_;
            $self->{ $sub2key{$subname} } = $set if(defined $set);
            $self->{ $sub2key{$subname} };
        }
    }
}

=head1 METHODS

=head2 C<new>

This is the object constructor, and returns an SNMP::Effective object.

=head3 Arguments

=over 4

=item C<max_sessions>

Maximum number of simultaneous SNMP sessions.

=item C<mastertimeout>

Maximum number of seconds before killing execute.

=back

All other arguments are passed on to $snmp_effective->add( ... ).

=cut

sub new {
    my $class = shift;
    my %args  = _format_arguments(@_);
    my %self  = (
                    maxsessions    => 1,
                    mastertimeout  => undef,
                    _sessions      => 0,
                    _hostlist      => SNMP::Effective::HostList->new,
                    _varlist       => [],
                    _arg           => {},
                    _callback      => sub {},
                    %args,
                );
    my $self  = (ref $class) ? $class : bless \%self, $class;

    $self->log( SNMP::Effective::Logger->new );
    $self->add( %args );

    $self->log->debug("Constructed SNMP::Effective Object");
    return $self;
}

=head2 C<add>

Adding information about what SNMP data to get and where to get it.

=head3 Arguments

=over 4

=item C<dest_host>

Either a single host, or an array-ref that holds a list of hosts. The format
is whatever C<SNMP> can handle.

=item C<arg>

A hash-ref of options, passed on to SNMP::Session.

=item C<callback>

A reference to a sub which is called after each time a request is finished.

=item C<heap>

This can hold anything you want. By default it's an empty hash-ref.

=item C<get> / C<getnext> / C<walk>

Either "oid object", "numeric oid", SNMP::Varbind SNMP::VarList or an
array-ref containing any combination of the above.

=item C<set>

Either a single SNMP::Varbind or a SNMP::VarList or an array-ref of any of
the above.

=back

This can be called with many different combinations, such as:

=over 4

=item C<dest_host> / any other argument

This will make changes per dest_host specified. You can use this to change arg,
callback or add OIDs on a per-host basis.

=item C<get> / C<getnext> / C<walk> / C<set>

The OID list submitted to C<add()> will be added to all dest_host, if no
dest_host is specified.

=item C<arg> / C<callback>

This can be used to alter all hosts' SNMP arguments or callback method.

=back

=cut

sub add {
    my $self        = shift;
    my %in          = _format_arguments(@_) or return;
    my $hostlist    = $self->hostlist;
    my $varlist     = $self->_varlist;
    my $new_varlist = [];

    ### setup host
    if($in{'desthost'} and ref $in{'desthost'} ne 'ARRAY') {
        $in{'desthost'} = [$in{'desthost'}];
        $self->log->info("Adding host(@{ $in{'desthost'} })");
    }

    ### setup varlist
    for my $key (keys %SNMP::Effective::Dispatch::METHOD) {
        next                    unless($in{$key});
        $in{$key} = [$in{$key}] unless(ref $in{$key});

        ### add to queue
        if(@{$in{$key}}) {
            $self->log->info("Adding $key(@{ $in{$key} })");
            unshift @{$in{$key}}, $key;
            push @$new_varlist, $in{$key};
        }
    }
    unless(@$new_varlist) {
        $new_varlist = $varlist;
    }

    ### add new hosts
    if(ref $in{'desthost'} eq 'ARRAY') {
        for my $addr (@{$in{'desthost'}}) {
            
            ### create new host
            unless($hostlist->{$addr}) {
                $hostlist->{$addr} = SNMP::Effective::Host->new(
                                         $addr, $self->log,
                                     );
                $hostlist->{$addr}->arg($self->arg);
                $hostlist->{$addr}->callback($self->callback);
            }

            ### alter created/existing host
            push @{$hostlist->{$addr}}, @$new_varlist;
            $hostlist->{$addr}->arg($in{'arg'});
            $hostlist->{$addr}->callback($in{'callback'});
            $hostlist->{$addr}->heap($in{'heap'});
        }
    }

    ### update hosts
    else {
        push @$varlist, @$new_varlist;
        $self->arg($in{'arg'})           if(ref $in{'arg'} eq 'HASH');
        $self->callback($in{'callback'}) if(ref $in{'callback'});
        $self->heap($in{'heap'})         if(defined $in{'heap'});
    }

    return 1;
}

=head2 C<execute>

This method starts setting and/or getting data. It will run as long as
necessary, or until C<master_timeout> seconds has passed. Every time some
data is set and/or retrieved, it will call the callback-method, as defined
globally or per host.

=cut

sub execute {
    my $self = shift;

    ### no hosts to get data from
    unless(scalar($self->hostlist)) {
        $self->log->warn("Cannot execute: No hosts defined");
        return 0;
    }

    ### setup lock
    $self->_init_lock;

    ### dispatch with master timoeut
    if(my $timeout = $self->master_timeout) {
        my $die_msg = "alarm_clock_timeout";

        $self->log->warn("Execute dispatcher with timeout ($timeout)");

        ### set alarm and call dispatch
        eval {
            local $SIG{'ALRM'} = sub { die $die_msg };
            alarm $timeout;
            $self->dispatch and SNMP::MainLoop();
            alarm 0;
        };

        ### check result from eval
        if($@ and $@ =~ /$die_msg/mx) {
            $self->master_timeout(0);
            $self->log->error("Master timeout!");
            SNMP::finish();
        }
        elsif($@) {
            $self->log->logdie($@);
        }
    }

    ### no master timeout
    else {
        $self->log->warn("Execute dispatcher without timeout");
        $self->dispatch and SNMP::MainLoop();
    }

    $self->log->warn("Done running the dispatcher");
    return 1;
}

sub _create_session {
    my $self = shift;
    my $host = shift;
    my $snmp;

    $!    = 0;
    $snmp = SNMP::Session->new(%SNMPARG, $host->arg);

    unless($snmp) {
        my($retry, $msg) = $self->_check_errno($!);
        $self->log->error("SNMP session failed for host $host: $msg");
        return ($retry) ? '' : undef;
    }

    $self->log->debug("SNMP session created for $host");
    return $snmp;
}

sub _check_errno {
    my $err    = pop;
    my $retry  = 0;
    my $string = '';

    ### some strange error
    unless($!) {
        $string  = "Couldn't resolve hostname";
    }
        
    ### some other error
    else {
        $string = "$!";
        if(
            $err == EINTR  ||  # Interrupted system call
            $err == EAGAIN ||  # Resource temp. unavailable
            $err == ENOMEM ||  # No memory (temporary)
            $err == ENFILE ||  # Out of file descriptors
            $err == EMFILE     # Too many open fd's
        ) {
            $string .= ' (will retry)';
            $retry   = 1;
        }
    }

    return($retry, $string);
}

=head1 FUNCTIONS

=head2 C<match_oid>

Takes two arguments: One OID to match against, and the OID to match.

 match_oid("1.3.6.10",   "1.3.6");    # return 10
 match_oid("1.3.6.10.1", "1.3.6");    # return 10.1
 match_oid("1.3.6.10",   "1.3.6.11"); # return undef

=cut

sub match_oid {
    my $p = shift or return;
    my $c = shift or return;
    return ($p =~ /^ \.? $c \.? (.*)/mx) ? $1 : undef;
}

=head2 C<make_numeric_oid>

Inverse of make_numeric_oid: Takes a list of mib-object strings, and turns
them into numeric format.

 make_numeric_oid("sysDescr"); # return .1.3.6.1.2.1.1.1 

=cut

sub make_numeric_oid {
    my @input = @_;
    
    for my $i (@input) {
        next if($i =~ /^ [\d\.]+ $/mx);
        $i = SNMP::translateObj($i);
    }
    
    return wantarray ? @input : $input[0];
}

=head2 C<make_name_oid>

Takes a list of numeric OIDs and turns them into an mib-object string.

 make_name_oid("1.3.6.1.2.1.1.1"); # return sysDescr

=cut

sub make_name_oid {
    my @input = @_;
    
    ### fix
    for my $i (@input) {
        $i = SNMP::translateObj($i) if($i =~ /^ [\d\.]+ $/mx);
    }
    
    return wantarray ? @input : $input[0];

}

sub _format_arguments {
    return if(@_ % 2 == 1);

    my %args = @_;

    for my $k (keys %args) {
        my $v =  delete $args{$k};
           $k =  lc $k;
           $k =~ s/_//gmx;
        $args{$k} = $v;
    }

    return %args;
}

sub _init_lock {
    my $self    = shift;
    my $LOCK_FH = $self->{'_lock_fh'};
    my $LOCK;

    close $LOCK_FH if(defined $LOCK_FH);
    open($LOCK_FH, "+<", \$LOCK) or die "Cannot create LOCK\n";

    $self->log->trace("Lock is ready and unlocked");

    return($self->{'_lock_fh'} = $LOCK_FH);
}

sub _wait_for_lock {
    my $self    = shift;
    my $LOCK_FH = $self->{'_lock_fh'};
    my $tmp;

    $self->log->trace("Waiting for lock to unlock...");
    flock $LOCK_FH, 2;
    $self->log->trace("The lock got unlocked, but is now locked again");

    return $tmp;
}

sub _unlock {
    my $self    = shift;
    my $LOCK_FH = $self->{'_lock_fh'};

    $self->log->trace("Unlocking lock");
    flock $LOCK_FH, 8;

    return;
}

=head1 The callback method

When C<SNMP> is done collecting data from a host, it calls a callback
method, provided by the C<< Callback => sub{} >> argument. Here is an example of a
callback method:

 sub my_callback {
     my($host, $error) = @_
  
     if($error) {
         warn "$host failed with this error: $error"
         return;
     }
 
     my $data = $host->data;
 
     for my $oid (keys %$data) {
         print "$host returned oid $oid with this data:\n";
 
         print join "\n\t",
               map { "$_ => $data->{$oid}{$_}" }
                   keys %{ $data->{$oid}{$_} };
         print "\n";
     }
 }

=head1 DEBUGGING

Debugging is enabled through Log::Log4perl. If nothing else is spesified,
it will default to "error" level, and print to STDERR. The component-name
you want to change is "SNMP::Effective", inless this module ins inherited.

=head1 NOTES

=head2 C<walk>

SNMP::Effective doesn't really do a SNMP native "walk". It makes a series
of "getnext", which is almost the same as SNMP's walk.

=head2 C<set>

If you want to use SNMP SET, you have to build your own varbind:

 $varbind = SNMP::VarBind($oid, $iid, $value, $type);
 $effective->add( set => $varbind );

=head1 DEPENDENCIES

In addition to the contents of the standard Perl distribution, this module
requires the following:

=over 4

=item L<Log::Log4perl>

By default the level of reporting is set to C<error> and will be directed
to C<STDERR>.

=item L<SNMP>

Note that this is B<not> the same as C<Net::SNMP> on the CPAN. You want the
C<SNMP> CPAN distribution or the C<SNMP> distribution.

=item L<Time::HiRes>

Perl versions greater than C<5.7.3> are supplied with this module.

=item L<Tie::Array>

Perl versions greater than C<5.5.0> are supplied with this module.

=item L<constant> and L<overload>

Perl versions greater than C<5.4.0> will have these modules.

=back

=head1 AUTHOR

Jan Henning Thorsen, C<< <pm at flodhest.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-effective at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNMP-Effective>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc SNMP::Effective

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNMP-Effective>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNMP-Effective>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SNMP-Effective>

=item * Search CPAN

L<http://search.cpan.org/dist/SNMP-Effective>

=back

=head1 ACKNOWLEDGEMENTS

Various contributions by Oliver Gorwits.

Sigurd Weisteen Larsen contributed with a better locking mechanism.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
