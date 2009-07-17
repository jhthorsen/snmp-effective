package SNMP::Effective::AttributeHelpers::MethodProvider::HostList;

=head1 NAME

SNMP::Effective::AttributeHelpers::MethodProvider::HostList

=head1 DESCRIPTION

This module does the role
L<SNMP::Effective::AttributeHelpers::MethodProvider::Hash>.

=head1 NOTES

This module adds a global Moose constraint: "SNMPEffectiveHost".

=cut

use Moose::Role;
use SNMP::Effective::Host;

with 'MooseX::AttributeHelpers::MethodProvider::Hash';

=head1 METHODS

=head2 set

 $code = $attribute->set($reader, $writer);
 $host_obj = $self->$code(\%args);
 $host_obj = $self->$code($host_obj);

Add a new L<SNMP::Effective::Host> object to list.

=cut

=head2 shift

 $code = $attribute->shift($reader, $writer);
 $host_obj = $self->$code;

Returns a semi-random host object from the hostlist.

=cut

sub shift : method {
    my($attr, $reader, $writer) = @_;

    return sub {
        my $hosts = $writer->($_[0]);
        my($key)  = keys %$hosts or return;
        return delete $hosts->{$key};
    }
}

=head2 is_empty

 $code = $attribute->is_empty($reader, $writer);
 $bool = $self->$code;

Returns true if the hostlist is empty.

=cut

sub is_empty : method {
    my($attr, $reader, $writer) = @_;

    return sub {
        return keys %{ $writer->($_[0]) } ? 0 : 1;
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
