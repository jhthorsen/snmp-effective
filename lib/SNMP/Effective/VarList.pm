
#================================
package SNMP::Effective::VarList;
#================================

use warnings;
use strict;
use SNMP;
use Tie::Array;
use constant METHOD => 0;
use constant OID    => 1;
use constant VALUE  => 2;
use constant TYPE   => 3;

our @ISA = qw/Tie::StdArray/;


sub PUSH { #==================================================================

    ### init
    my $self = shift;
    my @args = @_;
    my @varlist;

    for my $r (@args) {
        my $varbind;

        ### test request
        next unless(ref $r eq 'ARRAY' and @$r > 1);
        next unless($SNMP::Effective::Dispatch::METHOD{$r->[METHOD]});

        ### try to guess value type
        if(defined $r->[VALUE]) {
            unless($r->[TYPE]) {
                my $v      = $r->[VALUE];
                $r->[TYPE] = $v =~ /^ \d+ $/mx                  ? 'INTEGER'
                           : $v =~ /^ (\d{1,3}\.){1,3} \d+ $/mx ? 'IPADDR'
                           :                                      'OCTETSTR'
                           ;
            }
        }

        ### create varbind
        if(ref $r->[OID] =~ /^SNMP::Var/mx) {
            $varbind = $r->[OID];
        }
        else {
            $varbind = SNMP::Varbind->new([
                           $r->[OID], undef, $r->[VALUE], $r->[TYPE]
                       ]);
        }

        ### append varbind/list
        push @$self, [ $r->[METHOD], $varbind ];
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

Possible formats of elements pushed onto the array:

 [$method, $oid]
 [$method, $oid, $value]
 [$method, $oid, $value, $type]
 [$method, $Varbind_obj]
 [$method, $VarList_obj]

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
