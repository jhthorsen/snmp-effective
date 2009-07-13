package SNMP::Effective::VarList;

=head1 NAME

SNMP::Effective::VarList - Helper module for SNMP::Effective

=head1 DESCRIPTION

This is a helper module for SNMP::Effective

=cut

use warnings;
use strict;
use SNMP;
use Tie::Array;

our @ISA     = qw/Tie::StdArray/;
our $VERSION = '1.05';

=head2 PUSH

=cut

sub PUSH {
    my $self = shift;
    my @args = @_;

    LIST:
    for my $list (@args) {
        next LIST unless(ref $list eq 'ARRAY' and @$list > 1);
        next LIST unless($SNMP::Effective::Dispatch::METHOD{$list->[0]});

        my $method = $list->[0];
        my $i      = 0;
        my @varlist;

        OID:
        for my $oid (@$list) {
            next unless($i++); # skip the first element

            ### create varbind
            if(ref $oid eq '') {
                $oid = SNMP::Varbind->new([
                           $oid, # undef, $value, $type
                       ]);
            }

            ### append varbind
            if(ref $oid eq 'SNMP::Varbind') {
                push @varlist, $oid;
                next OID;
            }

            ### append varlist
            if(ref $oid eq 'SNMP::VarList') {
                push @varlist, @$oid;
                next OID;
            }
        }

        ### add varlist
        if(@varlist) {
            push @$self, [ $method, SNMP::VarList->new(@varlist) ];
        }
    }

    return $self->FETCHSIZE;
}

=head1 NOTES

Possible formats of list pushed onto the array:

 (
     [$method1, $oid1],         [$method2, $oid2],
     [$method1, $Varbind_obj1], [$method2, $Varbind_obj2],
     [$method1, $VarList_obj1], [$method2, $VarList_obj2],
 );

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>.

=cut

1;
