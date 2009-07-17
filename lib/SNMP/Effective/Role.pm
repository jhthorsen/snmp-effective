package SNMP::Effective;

=head1 NAME

SNMP::Effective::Role - Common attributes and methods

=head1 SYNOPSIS

 package Foo;
 with SNMP::Effective::Role;
 #...
 1;

=cut

use Moose::Role;
use SNMP::Effective::AttributeHelpers::Trait::VarList;
use SNMP;

=head1 OBJECT ATTRIBUTES

=head2 arg

 $hash_ref = $self->arg;

Returns a hashref holding the L<SNMP::Session> arguments.

Default:

 {
   Version => '2c',
   Community => 'public',
   Timeout => 1e6,
   Retries => 2,
 }

=cut

has arg => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{
        Version   => '2c',
        Community => 'public',
        Timeout   => 1e6,
        Retries   => 2
    } },
);

=head2 heap

 $value = $self->heap;

Returns whatever heap might hold. Returns a hashref by default.

=cut

has heap => (
    is => 'rw',
    isa => 'Any',
    default => sub { {} },
);

=head2 callback

 $code = self->callback;

Returns a ref to the default callback sub-routine.

=cut

has callback => (
    is => 'rw',
    isa => 'CodeRef',
    default => sub { sub {} },
);

has _varlist => (
    traits => [qw/SNMP::Effective::AttributeHelpers::Trait::VarList/],
    provides => {
        push => 'add_varlist',
        shift => 'shift_varbind',
    },
);

=head1 METHODS

=head2 add_varlist

 $int = $self->add_varlist($array_ref);
 $int = $self->add_varlist($varbind_obj);

Add a list of VarBinds.

=head2 shift_varbind

 $varbind_obj = $self->shift_varbind;

Return one $varbind object.

=head1 BUGS

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>

=cut

1;
