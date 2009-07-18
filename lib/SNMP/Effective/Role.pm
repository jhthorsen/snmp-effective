package SNMP::Effective::Role;

=head1 NAME

SNMP::Effective::Role - Common attributes and methods

=head1 SYNOPSIS

 package Foo;
 with SNMP::Effective::Role;
 #...
 1;

=cut

use Moose::Role;
use Log::Log4perl;
use Data::Dumper ();
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

has _log => (
    is => 'ro',
    isa => 'Any',
    default => sub {
        Log::Log4perl->easy_init unless(Log::Log4perl->initialized);
        Log::Log4perl->get_logger;
    },
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

=head2 log

 $bool = $self->log($level, $format, @args);
 $bool = $self->log->$level($msg);

Will log using L<Log::Log4perl>.

=cut

sub log {
    return $_[0]->_log if(@_ == 1);

    my $self   = shift;
    my $level  = shift;
    my $format = shift;
    my @args;

    return unless $self->_log->${ \"is_$level" };

    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Sortkeys = 1;

    for(@_) {
        push @args,
              ref $_     ? Data::Dumper::Dumper($_)
            : defined $_ ? $_
            :              "__UNDEF__";
    }

    return $self->_log->$level(sprintf $format, @args);
}

=head1 BUGS

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>

=cut

1;
