
#=================================
package SNMP::Effective::Dispatch;
#=================================

use strict;
use warnings;
use Time::HiRes qw/usleep/;


sub _set { #==================================================================

    ### init
    my $self     = shift;
    my $host     = shift;
    my $request  = shift;
    my $response = shift;

    ### timeout
    unless(ref $response) {
        return $self->_end($host, 'Timeout');
    }

    ### handle response
    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->data($r, $cur_oid);
    }

    ### the end
    $self->_end($host);
}

sub _get { #==================================================================

    ### init
    my $self     = shift;
    my $host     = shift;
    my $request  = shift;
    my $response = shift;

    ### timeout
    unless(ref $response) {
        return $self->_end($host, 'Timeout');
    }

    ### handle response
    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->data($r, $cur_oid);
    }

    ### the end
    $self->_end($host);
}

sub _walk { #=================================================================

    ### init
    my $self     = shift;
    my $host     = shift;
    my $request  = shift;
    my $response = shift;
    my $i        = 0;

    ### timeout
    unless(ref $response) {
        return $self->_end($host, 'Timeout');
    }

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
        $$host->getnext($response, [ \&_walk, $self, $host, $request ]);
    }

    ### the end
    else {
        $self->_end($host);
    }
}

sub _end { #==================================================================

    ### init
    my $self  = shift;
    my $host  = shift;
    my $error = shift;

    ### cleanup
    $self->log->debug("_end called for host $host - calling callback...");
    $host->callback->($host, $error);

    ### the end
    $self->dispatch($host)
}

sub dispatch { #==============================================================

    ### init
    my $self     = shift;
    my $host     = shift;
    my $hostlist = $self->hostlist;
    my $log      = $self->log;
    my $request;

    ### setup
    usleep 900 + int rand 200 while($self->lock);
    $self->lock(1);

    ### iterate host list
    while($self->_sessions < $self->max_sessions or $host) {

        ### init
        $host    ||= shift @$hostlist or last;
        $request   = shift @$host;
        my $sess_id;

        ### test request
        next unless(ref $request);

        ### fetch or create snmp session
        unless($$host) {
            unless($$host = $self->_create_session($host)) {
                next;
            }
            $self->{'_sessions'}++;
        }

        ### ready request
        if($$host->can($request->[0]) and $self->can("_$request->[0]")) {
            no strict;
            $cb      = \&{__PACKAGE__ ."::_$request->[0]"};
            $method  = $SNMP::Effective::METHOD{ $request->[0] };
            $sess_id = $$host->$method(
                           $request->[1], [$cb, $self, $host, $request->[1]]
                       );
            $log->debug("$host -> $method : $request->[1]");
        }

        ### something went wrong
        unless($sess_id) {
            $log->info("Method: $request->[0] failed \@ $host");
            next;
        }
    }
    continue {
        if(ref $$host and !ref $request) {
            $self->{'_sessions'}--;
            $log->info("complete: $host");
        }
        $host = undef;
    }

    ### the end
    $self->lock(0);
    $log->debug($self->_sessions ." < " .$self->max_sessions);
    unless(@$hostlist or $self->_sessions) {
        $log->info("SNMP::finish() is next up");
        SNMP::finish();
    }

    ### the end
    return @$hostlist || $self->_sessions;
}

#=============================================================================
1983;
__END__

=head1 NAME

SNMP::Effective::Dispatch - Helper module for SNMP::Effective

=head1 VERSION

This document refers to version 0.01 of SNMP::Effective::Dispatch.

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

