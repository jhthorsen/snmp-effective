package SNMP::Effective::Dispatch;

=head1 NAME

SNMP::Effective::Dispatch - Helper module for SNMP::Effective

=head1 DESCRIPTION

This is a helper module for L<SNMP::Effective>

=cut

use strict;
use warnings;

our %METHOD = (
    get     => 'get',
    getnext => 'getnext',
    walk    => 'getnext',
    set     => 'set',
);

=head1 METHODS

=head2 dispatch

 $self->dispatch($host);

This method does the actual fetching, and is called by
L<SNMP::Effective::execute()>.

=cut

sub dispatch {
    my $self     = shift;
    my $host     = shift;
    my $hostlist = $self->hostlist;
    my $log      = $self->log;
    my $request;
    my $req_id;

    $self->_wait_for_lock;

    HOST:
    while($self->{'_sessions'} < $self->max_sessions or $host) {
        $host         ||= shift @$hostlist or last HOST;
        $request        = shift @$host     or next HOST;
        $req_id         = undef;
        my $snmp_method = $METHOD{ $request->[0] };

        ### fetch or create snmp session
        unless($$host) {
            unless($$host = $self->_create_session($host)) {
                next HOST;
            }
            $self->{'_sessions'}++;
        }

        ### ready request
        if($$host->can($snmp_method) and $self->can($request->[0])) {
            $req_id = $$host->$snmp_method(
                          $request->[1],
                          [ $request->[0], $self, $host, $request->[1] ]
                      );
            $log->debug(
                "\$self->_$request->[0]( ${host}->$snmp_method(...) )"
            );
        }

        ### something went wrong
        unless($req_id) {
            $log->info("Method $request->[0] failed \@ $host");
            next HOST;
        }
    }
    continue {
        if(ref $$host and !ref $request) {
            $self->{'_sessions'}--;
            $log->info("Completed $host");
        }
        if($req_id or !@$host) {
            $host = undef;
        }
    }

    $log->debug(sprintf "Sessions/max-sessions: %i<%i",
        $self->{'_sessions'}, $self->max_sessions
    );

    unless(@$hostlist or $self->{'_sessions'}) {
        $log->info("SNMP::finish() is next up");
        SNMP::finish();
    }

    $self->_unlock;

    return @$hostlist || $self->{'_sessions'};
}

=head2 set

 $self->set($host, $request, $response);

This method is called after L<SNMP>.pm has completed it's C<set> call
on the C<$host>.

=cut

sub set {
    my $self     = shift;
    my $host     = shift;
    my $request  = shift;
    my $response = shift;

    return $self->end($host, 'Timeout') unless(ref $response);

    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->data($r, $cur_oid);
    }

    return $self->end($host);
}

=head2 get

 $self->get($host, $request, $response);

This method is called after L<SNMP>.pm has completed it's C<get> call
on the C<$host>.

=cut

sub get {
    my $self     = shift;
    my $host     = shift;
    my $request  = shift;
    my $response = shift;

    return $self->end($host, 'Timeout') unless(ref $response);

    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->data($r, $cur_oid);
    }

    return $self->end($host);
}

=head2 getnext

 $self->getnext($host, $request, $response);

This method is called after L<SNMP>.pm has completed it's C<getnext> call
on the C<$host>.

=cut

sub getnext {
    my $self     = shift;
    my $host     = shift;
    my $request  = shift;
    my $response = shift;

    return $self->end($host, 'Timeout') unless(ref $response);

    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->data($r, $cur_oid);
    }

    return $self->end($host);
}

=head2 walk

 $self->walk($host, $request, $response);

This method is called after L<SNMP>.pm has completed it's C<getnext> call
on the C<$host>. It will continue sending C<getnext> requests, until an
OID branch is walked.

=cut

sub walk {
    my $self     = shift;
    my $host     = shift;
    my $request  = shift;
    my $response = shift;
    my $i        = 0;

    return $self->end($host, 'Timeout') unless(ref $response);

    while($i < @$response) {
        my $splice = 2;

        if(my $r = $response->[$i]) {
            my($cur_oid, $ref_oid) = SNMP::Effective::make_numeric_oid(
                                         $r->name, $request->[$i]->name
                                     );
            $r->[0] = $cur_oid;
            $splice--;

            if(defined SNMP::Effective::match_oid($cur_oid, $ref_oid)) {
                $host->data($r, $ref_oid);
                $splice--;
                $i++;
            }
        }

        if($splice) {
            splice @$request, $i, 1;
            splice @$response, $i, 1;
        }
    }

    if(@$response) {
        $$host->getnext($response, [ \&_walk, $self, $host, $request ]);
        return;
    }
    else {
        return $self->end($host);
    }
}

=head2 end

 $self->end($host, $error);

This method is called from inside one of the callbacks (set, get, getnext
or walk) and will call the user specified callback:

 $callback->($host, $error);

It will then return to L<dispatcher()>.

=cut

sub end {
    my $self  = shift;
    my $host  = shift;
    my $error = shift;

    $self->log->debug("Calling callback for $host...");
    $host->callback->($host, $error);
    $host->clear_data;

    return $self->dispatch($host)
}

=head1 DEBUGGING

Debugging is enabled through L<Log::Log4perl>. If nothing else is spesified,
it will default to "error" level, and print to STDERR. The component-name
you want to change is L<SNMP::Effective>, inless this module ins inherited.

=head1 NOTES

=head2 %SNMP::Effective::Dispatch::METHOD

This hash contains a mapping between $effective->add($key => []),
C<SNMP::Effective::Dispatch::$key()> and L<SNMP>.pm's C<$value> method.
This means that you can actually add your custom method if you like.

The L<walk()> method, is a working example on this, since it's actually
a series of getnext, seen from L<SNMP>.pm's perspective.

=head1 AUTHOR

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

See L<SNMP::Effective>.

=cut

1;
