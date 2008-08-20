
#=================================
package SNMP::Effective::Dispatch;
#=================================

use strict;
use warnings;

our %METHOD = (
    get     => 'get',
    getnext => 'getnext',
    walk    => 'getnext',
    set     => 'set',

    get     => 'get_request',
    getnext => 'get_next_request',
    walk    => 'get_next_request',
    set     => 'set_request',
);


sub _set { #==================================================================
    my $self    = shift;
    my $host    = shift;
    my $request = shift;

    if(my $err = $$host->error) {
        return $self->_end($host, $err);
    }
    else {
        $host->_save_data($request);
        return $self->_end($host);
    }
}

sub _get { #==================================================================
    my $self    = shift;
    my $host    = shift;
    my $request = shift;

    if(my $err = $$host->error) {
        return $self->_end($host, $err);
    }
    else {
        $host->_save_data($request);
        return $self->_end($host);
    }
}

sub _getnext { #==============================================================
    my $self    = shift;
    my $host    = shift;
    my $request = shift;

    if(my $err = $$host->error) {
        return $self->_end($host, $err);
    }
    else {
        $host->_save_data($request);
        return $self->_end($host);
    }
}

sub _walk { #=================================================================
    my $self    = shift;
    my $host    = shift;
    my $request = shift;
    my(@names, $i);

    if(my $err = $$host->error) {
        return $self->_end($host, $err);
    }
    else {
        @names = $$host->var_bind_names;
        $i     = 0;
    }

    OID:
    while($i < @names) {
        my $name  = $names[$i];
        my $ref   = shift @$request or next OID;
        my $match = SNMP::Effective::match_oid($name, $ref);

        if(defined $match) {
            $host->_save_data([$ref], [$name]);
        }
        else {
            splice @names, $i, 1;
        }
    }
    continue {
        $i++;
    }

    if(@names) {
        return $$host->get_next_request(
            -varbindlist => \@names,
            -callback    => sub { $self->_walk($host, \@names) },
        );
    }
    else {
        return $self->_end($host);
    }
}

sub _end { #==================================================================
    my $self  = shift;
    my $host  = shift;
    my $error = shift;

    $self->log->debug("Calling callback for $host...");
    $host->callback->($host, $error);
    $host->_clear_data;

    if($self->{'no_retry'} and $error) {
        return $self->dispatch;
    }
    else {
        return $self->dispatch($host);
    }
}

sub dispatch { #==============================================================
    my $self     = shift;
    my $_host    = shift;
    my $hostlist = $self->hostlist;
    my $log      = $self->log;

    $self->_wait_for_lock;

    HOST:
    while($self->{'_sessions'} < $self->max_sessions or $_host) {
        my($host, $request);

        ### handle incoming host
        if($_host) {
            $host  = $_host;
            $_host = undef;
        }

        SETUP_SNMP_SESSION:
        {
            $host    ||= shift @$hostlist or last SETUP_SNMP_SESSION;
            $request   = shift @$host     or last SETUP_SNMP_SESSION;

            ### fetch or create snmp session
            unless($$host) {
                if($$host = $self->_create_session($host)) {
                    $self->{'_sessions'}++;
                }
                else {
                    last SETUP_SNMP_SESSION;
                }
            }

            ### make request
            if(my $error = $self->_snmp_request($host, $request)) {
                $self->log->error($error);
            }
        }

        ### done with host
        if(ref $host and ref $$host and !ref $request) {
            $self->{'_sessions'}--;
            $log->info("Completed $host");
        }

        ### done with all hosts
        unless(@$hostlist) {
            last HOST;
        }
    }

    $log->debug(sprintf "Sessions/max-sessions: %i<%i",
        $self->{'_sessions'}, $self->max_sessions
    );

    unless(@$hostlist or $self->{'_sessions'}) {
        $log->info("Done");
    }

    $self->_unlock;
    return @$hostlist || $self->{'_sessions'};
}

sub _snmp_request { #=========================================================

    my $self        = shift;
    my $host        = shift;
    my $req         = shift;
    my $self_method = "_" .$req->[0];
    my $snmp_method = $METHOD{ $req->[0] };
    my $r;

    #### detect for obvious errors
    unless($$host->can($snmp_method)) {
        return "Net::SNMP cannot do: $snmp_method";
    }
    unless($self->can($self_method)) {
        return "SNMP::Effective cannot do: $self_method";
    }

    #$$host->debug(0x02);

    ### ready request
    $$host->$snmp_method(
        -varbindlist => $req->[1],
        -callback    => [ sub { $self->$self_method($host, $req->[1], @_) } ],
    ) and return; # happy ending

    ### something went wrong
    return(sprintf
        "Method %s failed on %s: %s", $snmp_method, $host, $$host->error
    );
}

#=============================================================================
1983;
__END__

=head1 NAME

SNMP::Effective::Dispatch - Helper module for SNMP::Effective

=head1 VERSION

See SNMP::Effective

=head1 DESCRIPTION

This is a helper module for SNMP::Effective

=head1 METHODS

=head2 C<dispatch>

This method does the actual fetching, and is called by
SNMP::Effective::execute

=head1 DEBUGGING

Debugging is enabled through Log::Log4perl. If nothing else is spesified,
it will default to "error" level, and print to STDERR. The component-name
you want to change is "SNMP::Effective", inless this module ins inherited.

=head1 NOTES

=head2 %SNMP::Effective::Dispatch::METHOD

This hash contains a mapping between $effective->add($key => []),
SNMP::Effective::Dispatch::_$key() and SNMP.pm's $value method. This means
that you can actually add your custom method if you like.

The SNMP::Effective::Dispatch::_walk() method, is a working example on this,
since it's actually a series of getnext, seen from SNMP.pm's perspective.

=head1 TODO

=head1 AUTHOR

Jan Henning Thorsen, C<< <pm at flodhest.net> >>

=head1 ACKNOWLEDGEMENTS

Various contributions by Oliver Gorwits.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

