package SNMP::Effective;

=head1 NAME

SNMP::Effective - An effective SNMP-information-gathering module

=head1 VERSION

This document refers to version 1.99_001 of SNMP::Effective.

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

use Moose;
use SNMP;

with qw/
    SNMP::Effective::Role
    SNMP::Effective::Lock
    SNMP::Effective::Callbacks
/;

our $VERSION = '1.99_001';

# this package does not exist, but variable exists for backward compat
%SNMP::Effective::Dispatch::METHOD = (
    get     => 'get',
    getnext => 'getnext',
    walk    => 'getnext',
    set     => 'set',
);

=head1 OBJECT ATTRIBUTES

=head2 master_timeout

 $seconds = $self->master_timeout;

Maximum seconds for L<execute()> to run. Default is -1, which means forever.

=cut

has master_timeout => (
    is => 'ro',
    isa => 'Int',
    default => -1,
);

=head2 max_sessions

 $int = $self->max_sessions;

How many concurrent hosts to retrieve data from.

=cut

has max_sessions => (
    is => 'ro',
    isa => 'Int',
    default => 1,
);

=head2 sessions

 $int = $self->sessions;
 $self->inc_sessions;
 $self->dec_sessions;

=cut

has sessions => (
    traits => [qw/MooseX::AttributeHelpers::Trait::Counter/],
    is => 'rw',
    isa => 'Int',
    default => 0,
    provides => {
        inc => 'inc_sessions',
        dec => 'dec_sessions',
        reset => '_reset_session_counter',
    },
);

has _method_map => (
    traits => [qw/MooseX::AttributeHelpers::Trait::Collection::Hash/],
    is => 'ro',
    isa => 'HashRef',
    default => sub { \%SNMP::Effective::Dispatch::METHOD },
    provides => {
        set => 'add_callback',
        get => 'get_callback',
    },
);

has _hostlist => (
    traits => [qw/SNMP::Effective::AttributeHelpers::Trait::HostList/],
    provides => {
        set => 'add_host',
        get => 'get_host',
        delete => 'delete_host',
        shift => 'shift_host',
        keys => 'hosts',
    },
);

=head1 METHODS

=head2 BUILDARGS

 $hash_ref = $self->BUILDARGS(%args);
 $hash_ref = $self->BUILDARGS({ foo => bar });

See L<METHODS ARGUMENTS>.

=cut

sub BUILDARGS {
    my $class = shift;
    my $args  = @_ % 2 ? $_[0] : {@_};

    my %translate = qw/
        mastertimeout master_timeout
        maxsessions   max_sessions
        desthost      dest_host
    /;

    for my $k (keys %$args) {
        my $v =  delete $args->{$k};
           $k =  lc $k;
           $k =~ s/_//gmx;
           $k =  $translate{$k} if($translate{$k});
        $args->{$k} = $v;
    }

    return $args;
}

=head2 add

 $self->add(%arguments);

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
    my $self = shift;
    my $in   = $self->BUILDARGS(@_) or return;

    local $in->{'varlist'}; # don't mangle input

    # setup host
    if($in->{'dest_host'}) {
        unless(ref $in->{'dest_host'} eq 'ARRAY') {
            $in->{'dest_host'} = [$in->{'dest_host'}];
        }
    }

    # setup varlist
    for my $k (keys %{ $self->_method_map }) {
        if($in->{$k}) {
            push @{ $in->{'varlist'} }, [
                $k => ref $in->{$k} eq 'ARRAY' ? @{$in->{$k}} : $in->{$k}
            ];
        }
    }

    # add
    if(ref $in->{'dest_host'} eq 'ARRAY') {
        $in->{'varlist'} ||= $self->_varlist;

        for my $addr (@{$in->{'dest_host'}}) {

            # remove from debug output
            local $in->{'dest_host'};
            delete $in->{'dest_host'};

            if(my $host = $self->get_host($addr)) {
                $self->log(debug => 'Update %s: %s', $addr, $in);
                $host->add_varlist(@{ $in->{'varlist'} });
                $self->add_host({ # replace existing host
                    address  => $addr,
                    arg      => $in->{'arg'}      || $host->arg,
                    heap     => $in->{'heap'}     || $host->heap,
                    callback => $in->{'callback'} || $host->callback,
                    varlist  => $host->_varlist,
                });
            }
            else {
                $self->log(debug => 'New %s: %s', $addr, $in);
                $self->add_host({
                    address  => $addr,
                    arg      => $in->{'arg'}      || $self->arg,
                    heap     => $in->{'heap'}     || $self->heap,
                    callback => $in->{'callback'} || $self->callback,
                    varlist  => $in->{'varlist'}  || $self->_varlist,
                });
            }
        }
    }

    # update
    else {
        $self->log(debug => 'Update main object: %s', $in);
        $self->add_varlist(@{$in->{'varlist'}}) if($in->{'varlist'});
        $self->arg($in->{'arg'})                if($in->{'arg'});
        $self->callback($in->{'callback'})      if($in->{'callback'});
        $self->heap($in->{'heap'})              if(defined $in->{'heap'});
    }

    return 1;
}

=head2 execute

 $bool = $self->execute;

This method starts setting and/or getting data. It will run as long as
necessary, or until L<master_timeout> seconds has passed. Every time some
data is set and/or retrieved, it will call the callback-method, as defined
globally or per host.

Return true on success, false if no hosts are set up and C<undef> if 
C<SNMP::MainLoop()> exit after L<master_timeout> seconds.

=cut

sub execute {
    my $self    = shift;
    my $timeout = $self->master_timeout;

    # no hosts to get data from
    unless($self->hosts) {
        $self->log(warn => 'Cannot execute: No hosts defined');
        return 0;
    }

    $self->log(warn => 'Execute dispatcher with timeout=%s', $timeout);

    if($self->_dispatch) {
        if($timeout) {
            eval {
                SNMP::MainLoop($timeout, sub { die "TIMEOUT\n" });
                1;
            } or return;
        }
        else {
            SNMP::MainLoop();
        }
    }

    $self->log(warn => 'Done running the dispatcher');

    return 1;
}

# called from execute() or _end()
sub _dispatch {
    my $self = shift;
    my $host = shift;
    my($request, $req_id, $snmp_method);

    $self->wait_for_lock;

    if($host and @$host == 0) {
        $self->log(info => '%s complete', "$host");
        $self->dec_sessions;
    }

    HOST:
    while($self->sessions < $self->max_sessions or $host) {
        $host      ||= $self->shift_host    or last HOST;
        $request     = $host->shift_varbind or next HOST;
        $snmp_method = $self->get_callback($request->[0]);
        $req_id      = undef;

        unless($host->has_session) {
            $self->inc_sessions;
        }
        unless($host->session) {
            # $host->fatal is set
            next HOST;
        }

        # ready request
        if($$host->can($snmp_method)) {
            $req_id = $$host->$snmp_method(
                          $request->[1],
                          [ $request->[0], $self, $host, $request->[1] ]
                      );
            $self->log(trace => '$self->_%s( %s->%s(...) )',
                $request->[0], $host, $snmp_method
            );
        }

        # something went wrong
        if($req_id) {
            $self->log(trace => "%s request %s", "$host", $request->[0]);
        }
        else {
            $host->fatal("Could not create request: " .$request->[0]);
            next HOST;
        }
    }
    continue {
        if($req_id or !@$host) {
            $host = undef;
        }
        elsif($host->fatal) {
            $self->log(error => '%s failed: %s', "$host", $host->fatal);
            $host = undef;
        }
    }

    $self->log(debug => 'Sessions/max-sessions: %i<%i',
        $self->sessions, $self->max_sessions
    );

    unless($self->hosts or $self->sessions) {
        $self->log(info => 'SNMP::finish() is next up');
        SNMP::finish();
    }

    $self->unlock;

    return $self->hosts || $self->sessions;
}

# called from inside a dispatch callback
sub _end {
    my $self  = shift;
    my $host  = shift;
    my $error = shift;

    $self->log(debug => 'Callback for %s...', $host);
    $host->($host, $error);
    $host->clear_data;

    return $self->_dispatch($host)
}

=head2 add_host

 $self->add_host($host_obj);
 $self->add_host([$hostname, %args]);
 $self->add_host(\%args);

=head2 get_host

 $host_obj = $self->get_host($hostname);

=head2 delete_host

 $host_obj = $self->delete_host($hostname);

=head2 hosts

 @hostnames = $self->hosts;

=head2 add_callback

 $self->add_method($dispatch_method => $snmp_method);

=head2 get_callback

 $snmp_method = $self->get_callback($dispatch_method);

=cut

=head1 The callback method

When C<SNMP> is done collecting data from a host, it calls a callback
method, provided by the C<< Callback => sub{} >> argument. Here is an
example of a callback method:

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

=head2 C<walk()>

SNMP::Effective doesn't really do a SNMP native "walk". It makes a series
of "getnext", which is almost the same as SNMP's walk.

=head2 C<set()>

If you want to use SNMP SET, you have to build your own varbind:

 $varbind = SNMP::VarBind($oid, $iid, $value, $type);
 $effective->add( set => $varbind );

=head2 Method map

This hash contains a mapping between $effective->add($key => []),
C<SNMP::Effective::Dispatch::$key()> and L<SNMP>.pm's C<$value> method.
This means that you can actually add your custom method if you like.

The L<walk()> method, is a working example on this, since it's actually
a series of getnext, seen from L<SNMP>.pm's perspective.

Use L<add_callback()> and L<get_callback()> to manipulate this behaviour.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-effective at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNMP-Effective>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Various contributions by Oliver Gorwits.

Sigurd Weisteen Larsen contributed with a better locking mechanism.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen, C<< <pm at flodhest.net> >>

=cut

1;
