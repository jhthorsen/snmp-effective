package SNMP::Effective::Lock;

=head1 NAME

SNMP::Effective::Lock - A role for locking

=head1 SYNOPSIS

 while(@tasks) {
   $self->wait_for_lock;
   # do stuff
   $self->unlock;
 }

=cut

use Moose::Role;

has _lock => (
    is => 'ro',
    default => sub {
        my $LOCK_FH;
        my $LOCK;
        open($LOCK_FH, "+<", \$LOCK) or die "Cannot create LOCK\n";
        return $LOCK_FH;
    },
);

=head1 METHODS

=head2 wait_for_lock

 $bool = $self->wait_for_lock;

Returns true when the lock has been released. Check C<$!> on failure.

=cut

sub wait_for_lock {
    my $self    = shift;
    my $LOCK_FH = $self->_lock;

    $self->log->trace("Waiting for lock to unlock...");
    flock $LOCK_FH, 2 or return;
    $self->log->trace("The lock got unlocked, but is now locked again");

    return 1;
}

=head2 unlock

 $bool = $self->unlock;

Will unlock the lock and return true. Check C<$!> on failure.

=cut

sub unlock {
    my $self    = shift;
    my $LOCK_FH = $self->_lock;

    $self->log->trace("Unlocking lock");
    flock $LOCK_FH, 8 or return;

    return 1;
}

=head1 ACKNOWLEDGEMENTS

Sigurd Weisteen Larsen contributed with a better locking mechanism.

=head1 BUGS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>

=cut

1;
