
#================================
package SNMP::Effective::VarList;
#================================

use warnings;
use strict;
use SNMP;
use Tie::Array;

our @ISA     = qw/Tie::StdArray/;
our $VERSION = '0.04';


sub PUSH { #==================================================================

    ### init
    my $self = shift;
    my @args = @_;

    LIST:
    for my $list (@args) {
        next LIST unless(ref $list eq 'ARRAY' and @$list > 1);
        next LIST unless($SNMP::Effective::Dispatch::METHOD{$list->[0]});

        my $method = $list->[0];
        my $i      = 0;
        my @varlist;

        OID:
        for my $oid (@$list) {
            next unless($i++); # skip the first element

            ### create varbind
            if(ref $oid eq '') {
                $oid = SNMP::Varbind->new([
                           $oid, # undef, $value, $type
                       ]);
            }

            ### append varbind
            if(ref $oid eq 'SNMP::Varbind') {
                push @varlist, $oid;
                next OID;
            }

            ### append varlist
            if(ref $oid eq 'SNMP::VarList') {
                push @varlist, @$oid;
                next OID;
            }
        }

        ### add varlist
        if(@varlist) {
            push @$self, [ $method, SNMP::VarList->new(@varlist) ];
        }
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

Possible formats of list pushed onto the array:

 (
     [$method1, $oid1],         [$method2, $oid2],
     [$method1, $Varbind_obj1], [$method2, $Varbind_obj2],
     [$method1, $VarList_obj1], [$method2, $VarList_obj2],
 );

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
