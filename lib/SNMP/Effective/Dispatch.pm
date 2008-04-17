
#=================================
package SNMP::Effective::Dispatch;
#=================================

use strict;
use warnings;

our $VERSION = '1.05';
our %METHOD  = (
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

    ### init
    my $self     = shift;
    my $host     = shift;
    my $request  = shift;
    my $response = $$host->var_bind_list;

    ### timeout
    return $self->_end($host, $$host->error) unless(ref $response);

    ### handle response
    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->data($r, $cur_oid);
    }

    ### the end
    return $self->_end($host);
}

sub _get { #==================================================================

    ### init
    my $self     = shift;
    my $host     = shift;
    my $request  = shift;
    my $response = $$host->var_bind_list;

    ### timeout
    return $self->_end($host, $$host->error) unless(ref $response);

    ### handle response
    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->data($r, $cur_oid);
    }

    ### the end
    return $self->_end($host);
}

sub _getnext { #==============================================================

    ### init
    warn join "|", @_;
    my $self     = shift;
    my $host     = shift;
    my $request  = shift;
    my $response = $$host->var_bind_list;

    ### timeout
    return $self->_end($host, $host->error) unless(ref $response);

    ### handle response
    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->data($r, $cur_oid);
    }

    ### the end
    return $self->_end($host);
}

sub _walk { #=================================================================

    ### init
    my $self     = shift;
    my $host     = shift;
    my $request  = shift;
    my $response = $$host->var_bind_list;
    my $i        = 0;

    ### timeout
    return $self->_end($host, $host->error) unless(ref $response);

    ### handle response
    while($i < @$response) {
        my $splice = 2;

        ### handle result
        if(my $r = $response->[$i]) {
            my($cur_oid, $ref_oid) = SNMP::Effective::make_numeric_oid(
                                         $r->name, $request->[$i]->name
                                     );
            $r->[0] = $cur_oid;
            $splice--;

            ### valid oid
            if(defined SNMP::Effective::match_oid($cur_oid, $ref_oid)) {
                $host->data($r, $ref_oid);
                $splice--;
                $i++;
            }
        }

        ### bad result
        if($splice) {
            splice @$request, $i, 1;
            splice @$response, $i, 1;
        }
    }

    ### to be continued
    if(@$response) {
        #$$host->getnext($response, [ \&_walk, $self, $host, $request ]);
        $$host->get_next_request(
            -varbindlist => $response,
            -callback    => sub { $self->_walk($host, $request) },
        );
        return;
    }

    ### no more to get
    else {
        return $self->_end($host);
    }
}

sub _end { #==================================================================

    ### init
    my $self  = shift;
    my $host  = shift;
    my $error = shift;

    die $host if $host;

    ### cleanup
    $self->log->debug("Calling callback for $host...");
    $host->callback->($host, $error);
    $host->clear_data;

    ### the end
    return $self->dispatch($host)
}

sub dispatch { #==============================================================

    ### init
    my $self     = shift;
    my $host     = shift;
    my $hostlist = $self->hostlist;
    my $log      = $self->log;

    ### setup
    $self->_wait_for_lock;

    unshift @$hostlist, $host if(ref $host);

    HOST:
    while($self->{'_sessions'} < $self->max_sessions or $host) {

        my($host, $request, $req_id, $snmp_method, $cb_method);

        CREATE_SNMP_SESSION:
        {
            ### init
            $host      ||= shift @$hostlist or last CREATE_SNMP_SESSION;
            $request     = shift @$host     or last CREATE_SNMP_SESSION;
            $req_id      = undef;
            $snmp_method = $METHOD{ $request->[0] };
            $cb_method   = "_" .$request->[0];

            ### fetch or create snmp session
            unless($$host) {
                unless($$host = $self->_create_session($host)) {
                    last CREATE_SNMP_SESSION;
                }
                $self->{'_sessions'}++;
            }

            ### ready request
            if($$host->can($snmp_method) and $self->can("_$request->[0]")) {
                #$req_id = $$host->$snmp_method(
                #              $request->[1],
                #              [ "_$request->[0]", $self, $host, $request->[1] ]
                #          );
                $$host->debug(0x08);
                $req_id = $$host->$snmp_method(
                            -varbindlist => $request->[1],
                            -callback    => sub { $self->$cb_method(
                                                $host, $request->[1]
                                            ) },
                        );
                $log->debug( "${host}->$snmp_method(...)" );
            }

            ### something went wrong
            unless($req_id) {
                $log->info(sprintf "Method %s failed on %s: %s",
                    $snmp_method, $host, $$host->error
                );
                last CREATE_SNMP_SESSION;
            }
        }

        if(ref $host and ref $$host and !ref $request) {
            $self->{'_sessions'}--;
            $log->info("Completed $host");
        }
    }

    ### the end
    $log->debug(sprintf "Sessions/max-sessions: %i<%i",
        $self->{'_sessions'}, $self->max_sessions
    );
    unless(@$hostlist or $self->{'_sessions'}) {
        $log->info("SNMP::finish() is next up");
       #SNMP::finish();
    }

    ### the end
    $self->_unlock;
    return @$hostlist || $self->{'_sessions'};
}

#=============================================================================
1983;
__END__

=head1 NAME

SNMP::Effective::Dispatch - Helper module for SNMP::Effective

=head1 VERSION

This document refers to version 1.05 of SNMP::Effective::Dispatch.

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

