
#================================
package SNMP::Effective::VarList;
#================================

use warnings;
use strict;
use SNMP;
use Tie::Array;
use constant METHOD => 0;
use constant OID    => 1;
use constant SET    => 2;

our @ISA = qw/Tie::StdArray/;


sub PUSH { #==================================================================

    ### init
    my $self = shift;
    my @args = @_;

    foreach my $r (@args) {

        ### test request
        next unless(ref $r eq 'ARRAY' and $r->[METHOD] and $r->[OID]);
        next unless($SNMP::Effective::Dispatch::METHOD{$r->[METHOD]});

        ### fix OID array
        $r->[OID] = [$r->[OID]] unless(ref $r->[OID] eq 'ARRAY');

        ### setup VarList
        my @varlist = map  {
                          ref $_ eq 'ARRAY' ? $_    :
                          /([0-9\.]+)/mx    ? [$1]  :
                                              undef ;
                      } @{$r->[OID]};

        ### add elements
        push @$self, [
                         $r->[METHOD],
                         SNMP::VarList->new( grep {$_} @varlist ),
                     ];
    }

    ### the end
    return $self->FETCHSIZE;
}

#=============================================================================
1983;
__END__

=head1 NAME

SNMP::Effective::VarList - Helper module for SNMP::Effective

=head1 VERSION

This document refers to version 0.04 of SNMP::Effective::VarList.

=head1 DESCRIPTION

This is a helper module for SNMP::Effective

=head1 METHODS

No methods. This class is used for Tieing the list of OIDs.

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
