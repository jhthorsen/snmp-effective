package SNMP::Effective::AttributeHelpers::Trait::HostList;

=head1 NAME

SNMP::Effective::AttributeHelpers::Trait::HostList

=head1 NOTES

This module adds a global Moose constraint: "SNMPEffectiveHost".

=cut

use Moose::Role;
use Moose::Util::TypeConstraints;

with 'MooseX::AttributeHelpers::Trait::Collection::Hash';

subtype 'SNMPEffectiveHost' => as 'SNMP::Effective::Host';
coerce 'SNMPEffectiveHost' => (
    from 'HashRef' => via { SNMP::Effective::Host->new($_) },
    from 'ArrayRef' => via { SNMP::Effective::Host->new(address => @$_) },
);

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

=head2 helper_type

 "ArrayRef" = $self->helper_type;

=cut

sub helper_type { 'ArrayRef' }

=head2 _process_options

Set default options unless specified:

 {
   is => 'ro',
   default => sub { [] },
   isa => 'HashRef[SNMPEffectiveHost]',
   coerce => 1,
 }

=cut

before _process_options => sub {
    my($class, $name, $options) = @_;

    $options->{'is'}      ||= 'ro';
    $options->{'default'} ||= {};
    $options->{'isa'}     ||= 'HashRef[SNMPEffectiveHost]';
    $options->{'coerce'}    = 1;
};

=head1 SEE ALSO

L<SNMP::Effective::AttributeHelpers::MethodProvider::VarList>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>.

=cut

1;
