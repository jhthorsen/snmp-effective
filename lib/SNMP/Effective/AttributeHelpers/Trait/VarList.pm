package SNMP::Effective::AttributeHelpers::Trait::VarList;

=head1 NAME

SNMP::Effective::AttributeHelpers::Trait::VarList

=cut

use Moose::Role;
use MooseX::AttributeHelpers;
use SNMP::Effective::AttributeHelpers::MethodProvider::VarList;

with 'MooseX::AttributeHelpers::Trait::Collection::Array';

=head1 ATTRIBUTES

=head2 method_provider

 $str = $self->method_provider;

=cut

has method_provider => (
    is => 'ro',
    isa => 'ClassName',
    predicate => 'has_method_provider',
    default => 'SNMP::Effective::AttributeHelpers::MethodProvider::VarList',
);

=head1 METHODS

=head2 _process_options

Set default options unless specified.

 {
   is => 'ro',
   default => [],
   isa => 'ArrayRef',
 }

=cut

before _process_options => sub {
    my($class, $name, $options) = @_;

    $options->{'is'}      ||= 'ro';
    $options->{'default'} ||= sub { [] };
    $options->{'isa'}     ||= 'ArrayRef';
};

=head1 SEE ALSO

L<SNMP::Effective::AttributeHelpers::MethodProvider::VarList>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>.

=cut

1;
