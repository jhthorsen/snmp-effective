package SNMP::Effective::AttributeHelpers::Trait::HostList;

=head1 NAME

SNMP::Effective::AttributeHelpers::Trait::HostList

=cut

use Moose::Role;
use SNMP::Effective::Host;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;
use SNMP::Effective::AttributeHelpers::MethodProvider::HostList;

with 'MooseX::AttributeHelpers::Trait::Collection::Hash';

=head1 ATTRIBUTES

=head2 method_provider

 $str = $self->method_provider;

=cut

has method_provider => (
    is => 'ro',
    isa => 'ClassName',
    predicate => 'has_method_provider',
    default => 'SNMP::Effective::AttributeHelpers::MethodProvider::HostList',
);

=head1 METHODS

=head2 _process_options

Set default options unless specified:

 {
   is => 'ro',
   isa => 'HashRef[SNMP::Effective::Host]',
   default => sub { [] },
 }

=cut

before _process_options => sub {
    my($class, $name, $options) = @_;

    $options->{'is'}      ||= 'ro';
    $options->{'isa'}     ||= 'HashRef[SNMP::Effective::Host]';
    $options->{'default'} ||= sub { {} };
};

=head1 SEE ALSO

L<SNMP::Effective::AttributeHelpers::MethodProvider::VarList>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>.

=cut

1;
