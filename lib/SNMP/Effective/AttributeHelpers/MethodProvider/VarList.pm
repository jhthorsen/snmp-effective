package SNMP::Effective::AttributeHelpers::MethodProvider::VarList;

=head1 NAME

SNMP::Effective::AttributeHelpers::MethodProvider::VarList

=head1 DESCRIPTION

This module does the role
L<SNMP::Effective::AttributeHelpers::MethodProvider::Array>.

=cut

use Moose::Role;
use SNMP;

with 'MooseX::AttributeHelpers::MethodProvider::Array';

=head1 METHODS

=head2 push

 $code = $attribute->push($reader, $writer);
 $int = $self->$code([$method1, $oid1],         [...]);
 $int = $self->$code([$method1, $Varbind_obj1], [...]);
 $int = $self->$code([$method1, $VarList_obj1], [...]);

C<$code> returns an int, with the number of total of varbind objects.

=cut

sub push : method {
    my($attribute, $reader, $writer) = @_;

    return sub {
        my $self = shift;
        my @args = @_;

        LIST:
        for my $list (@args) {
            next LIST unless(ref $list eq 'ARRAY' and @$list > 1);

            my $method = $list->[0];
            my @varlist;

            OID:
            for my $oid (@$list) {
                next if($oid eq $method); # skip the first element

                # create varbind
                if(ref $oid eq '') {
                    $oid = SNMP::Varbind->new([
                               $oid, # undef, $value, $type
                           ]);
                }

                # append varbind
                if(ref $oid eq 'SNMP::Varbind') {
                    push @varlist, $oid;
                    next OID;
                }

                # append varlist
                if(ref $oid eq 'SNMP::VarList') {
                    push @varlist, @$oid;
                    next OID;
                }
            }

            # add varlist
            if(@varlist) {
                push(@{ $reader->($self) },
                    [ $method, SNMP::VarList->new(@varlist) ]
                );
            }
        }

        return int @{ $reader->($self); };
    };
}

=head1 SEE ALSO

L<SNMP::Effective::AttributeHelpers::Trait::VarList>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>.

=cut

1;
