package SNMP::Effective::Callbacks;

=head1 NAME

SNMP::Effective::Callbacks - Callback class for SNMP::Effective

=head1 DESCRIPTION

This is a helper module for L<SNMP::Effective>

=cut

use Moose;

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

    return $self->_end($host, 'Timeout') unless(ref $response);

    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->set_data($r, $cur_oid);
    }

    return $self->_end($host);
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

    return $self->_end($host, 'Timeout') unless(ref $response);

    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->set_data($r, $cur_oid);
    }

    return $self->_end($host);
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

    return $self->_end($host, 'Timeout') unless(ref $response);

    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->set_data($r, $cur_oid);
    }

    return $self->_end($host);
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

    return $self->_end($host, 'Timeout') unless(ref $response);

    while($i < @$response) {
        my $splice = 2;

        if(my $r = $response->[$i]) {
            my($cur_oid, $ref_oid) = SNMP::Effective::make_numeric_oid(
                                         $r->name, $request->[$i]->name
                                     );
            $r->[0] = $cur_oid;
            $splice--;

            if(defined SNMP::Effective::match_oid($cur_oid, $ref_oid)) {
                $host->set_data($r, $ref_oid);
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
        return $self->_end($host);
    }
}

=head1 DEBUGGING

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>.

=cut

1;
