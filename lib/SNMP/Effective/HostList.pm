package SNMP::Effective::HostList;

=head1 NAME

SNMP::Effective::HostList - Helper module for SNMP::Effective

=head1 DESCRIPTION

This is a helper module for SNMP::Effective

=cut

use warnings;
use strict;
use overload '""'  => sub { 0 + keys %{ $_[0] } };
use overload '@{}' => sub {
                          my @Array;
                          tie @Array, ref $_[0], $_[0];
                          return \@Array;
                      };

=head1 METHODS

=head2 new

=cut

sub new {
    return bless {}, $_[0];
}

=head2 TIEARRAY

=cut

sub TIEARRAY {
    return $_[1];
}

=head2 FETCHSIZE

=cut

sub FETCHSIZE {
    return 0 + keys %{$_[0]};
}

=head2 SHIFT

=cut

sub SHIFT {
    my $self = shift;
    my $key  = (keys %$self)[0] or return;
    return delete $self->{$key};
}

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>.

=cut

1;
