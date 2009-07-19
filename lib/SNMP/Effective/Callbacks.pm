package SNMP::Effective::Callbacks;

=head1 NAME

SNMP::Effective::Callbacks - SNMP callbacks

=head1 DESCRIPTION

This package contains callback methods for L<SNMP::Effective>. These methods
are called from within an L<SNMP> get/getnext/set/... method and
should handle the response from a SNMP client.

=cut

use strict;
use warnings;
use SNMP::Effective;
use SNMP::Effective::Utils qw/:all/;

=head1 CALLBACKS

=head2 set

 set($snmp_effective, $host, $request, $response);

This method is called after L<SNMP>.pm has completed it's C<set> call
on the C<$host>.

=cut

SNMP::Effective->add_snmp_callback(set => set => sub {
    my($self, $host, $req, $res) = @_;

    return $self->_end($host, 'Timeout') unless(ref $res);

    for my $r (grep { ref $_ } @$res) {
        my $cur_oid = make_numeric_oid($r->name);
        $host->set_data($r, $cur_oid);
    }

    return $self->_end($host);
});

=head2 get

 get($snmp_effective, $host, $request, $response);

This method is called after L<SNMP>.pm has completed it's C<get> call
on the C<$host>.

=cut

SNMP::Effective->add_snmp_callback(get => get => sub {
    my($self, $host, $req, $res) = @_;

    return $self->_end($host, 'Timeout') unless(ref $res);

    for my $r (grep { ref $_ } @$res) {
        my $cur_oid = make_numeric_oid($r->name);
        $host->set_data($r, $cur_oid);
    }

    return $self->_end($host);
});

=head2 getnext

 getnext($snmp_effective, $host, $request, $response);

This method is called after L<SNMP>.pm has completed it's C<getnext> call
on the C<$host>.

=cut

SNMP::Effective->add_snmp_callback(getnext => getnext => sub {
    my($self, $host, $req, $res) = @_;

    return $self->_end($host, 'Timeout') unless(ref $res);

    for my $r (grep { ref $_ } @$res) {
        my $cur_oid = make_numeric_oid($r->name);
        $host->set_data($r, $cur_oid);
    }

    return $self->_end($host);
});

=head2 walk

 walk($snmp_effective, $host, $request, $response);

This method is called after L<SNMP>.pm has completed it's C<getnext> call
on the C<$host>. It will continue sending C<getnext> requests, until an
OID branch is walked.

=cut

SNMP::Effective->add_snmp_callback(walk => getnext => sub {
    my($self, $host, $req, $res) = @_;
    my $i = 0;

    return $self->_end($host, 'Timeout') unless(ref $res);

    while($i < @$res) {
        my $splice = 2;

        if(my $r = $res->[$i]) {
            my($cur_oid, $ref_oid) = make_numeric_oid(
                                         $r->name, $req->[$i]->name
                                     );
            $r->[0] = $cur_oid;
            $splice--;

            if(defined match_oid($cur_oid, $ref_oid)) {
                $host->set_data($r, $ref_oid);
                $splice--;
                $i++;
            }
        }

        if($splice) {
            splice @$req, $i, 1;
            splice @$res, $i, 1;
        }
    }

    if(@$res) {
        $$host->getnext($res, [ \&_walk, $self, $host, $req ]);
        return;
    }
    else {
        return $self->_end($host);
    }
});

=head1 DEBUGGING

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>.

=cut

1;
