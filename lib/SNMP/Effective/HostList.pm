
#=================================
package SNMP::Effective::HostList;
#=================================

use warnings;
use strict;
use overload '""'  => sub { 0 + keys %{ $_[0] } };
use overload '@{}' => sub {
                          my @Array;
                          tie @Array, ref $_[0], $_[0];
                          return \@Array;
                      };

our $VERSION = '1.05';


sub TIEARRAY { #==============================================================
    return $_[1];
}

sub FETCHSIZE { #=============================================================
    return 0 + keys %{$_[0]};
}

sub SHIFT { #=================================================================
    my $self = shift;
    my $key  = (keys %$self)[0] or return;
    return delete $self->{$key};
}

sub new { #===================================================================
    return bless {}, $_[0];
}

#=============================================================================
1983;
__END__

=head1 NAME

SNMP::Effective::HostList - Helper module for SNMP::Effective

=head1 VERSION

This document refers to version 1.05 of SNMP::Effective::HostList.

=head1 DESCRIPTION

This is a helper module for SNMP::Effective

=head1 METHODS

=head2 C<new>

Constructor

=head1 DEBUGGING

Debugging is enabled through Log::Log4perl. If nothing else is spesified,
it will default to "error" level, and print to STDERR. The component-name
you want to change is "SNMP::Effective", inless this module ins inherited.

=head1 NOTES

=head1 TODO

=head1 AUTHOR

Jan Henning Thorsen, C<< <pm at flodhest.net> >>

=head1 ACKNOWLEDGEMENTS

Various contributions by Oliver Gorwits.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

