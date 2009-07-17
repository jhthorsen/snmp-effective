package SNMP::Effective::Host;

=head1 NAME

SNMP::Effective::Host - Helper module for SNMP::Effective

=head1 DESCRIPTION

This is a helper module for SNMP::Effective. It does the role
L<SNMP::Effective::Role>.

=cut

use Moose;
use SNMP;
use POSIX qw/:errno_h/;
use overload (
    q("")  => sub { shift->address },
    q(${}) => sub { shift->session },
    q(&{}) => sub { shift->callback },
    q(@{}) => sub { shift->_varlist },
    fallback => 1,
);

with 'SNMP::Effective::Role';

=head1 OBJECT ATTRIBUTES

=head2 address

 $address = $self->address;
 $address = "$self";

Returns host address.

=cut

has address => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

=head2 sesssion

 $snmp_session = $self->session;
 $snmp_session = $$self;
 $bool => $self->has_session;
 $self->clear_session;

Returns a L<SNMP::Session> or undef on failure.

=cut

has session => (
    is => 'ro',
    isa => 'Maybe[SNMP::Session]',
    lazy_build => 1,
);

sub _build_session {
    my $self = shift;
    local $! = 0;

    if(my $session = SNMP::Session->new($self->arg)) {
        $self->fatal("");
        return $session;
    }
    else {
        my($retry, $msg) = _check_errno();
        $self->fatal($msg);
        return;
    }
}

=head2 data

 $hash_ref = $self->data;

Get the retrieved data:

 {
   $oid => {
     $iid => $value,
     ...,
   },
   ...,
 }

=cut

has data => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
    clearer => '_clear_data',
);

=head2 type

 $hash_ref = $self->type;

Get SNMP type.

 {
   $oid => {
     $iid => $type,
     ...,
   },
   ...,
 }

=cut

has type => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
    clearer => '_clear_type',
);

=head2 fatal

 $str = $self->fatal;

Returns a string if the host should stop retrying an action. Example:

 until($session = $self->session) {
    die $self->fatal if($self->fatal);
 }

=cut

has fatal => (
    is => 'rw',
    isa => 'Str',
    default => "",
);

=head1 METHODS

=head2 add_data

 $bool = $self->add_data([$oid, $iid, $value, $type], $ref_oid);

C<$iid> and C<$ref_oid> can be undef.

=cut

sub add_data {
    my $self = shift;
    my $r    = shift or return;
    my $ref  = shift || q(.);
    my $iid  = $r->[1] || SNMP::Effective::match_oid($r->[0], $ref) || 1;

    $self->data->{$ref}{$iid} = $r->[2];
    $self->type->{$ref}{$iid} = $r->[3];

    return 1;
}

=head2 clear_data

 $self->clear_data;

Remove data from the host cache

=cut

sub clear_data {
    $_[0]->_clear_data;
    $_[0]->_clear_type;
    return;
}

# ($retry, $reason) = _check_errno;
sub _check_errno {
    my $err    = $!;
    my $string = "$!";
    my $retry  = 0;

    if($err) {
        if(
            $err == EINTR  ||  # Interrupted system call
            $err == EAGAIN ||  # Resource temp. unavailable
            $err == ENOMEM ||  # No memory (temporary)
            $err == ENFILE ||  # Out of file descriptors
            $err == EMFILE     # Too many open fd's
        ) {
            $string .= ' (will retry)';
            $retry   = 1;
        }
    }
    else {
        $string  = "Couldn't resolve hostname";  # guesswork
    }

    return $retry, $string;
}

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>.

=cut

1;
