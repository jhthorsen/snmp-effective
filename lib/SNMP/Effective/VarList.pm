
#================================
package SNMP::Effective::VarList;
#================================

use warnings;
use strict;
use Tie::Array;

our @ISA = qw/Tie::StdArray/;


sub PUSH { #==================================================================
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

            if(ref $oid eq 'ARRAY' and @$oid == 3) {
                $oid->[0] = SNMP::Effective::make_numeric_oid($oid->[0]);
                push @varlist, $oid;
            }
            elsif(!ref $oid) {
                $oid = SNMP::Effective::make_numeric_oid($oid);
                push @varlist, $oid;
            }
        }

        ### add varlist
        push @$self, [ $method, \@varlist ] if(@varlist);
    }

    return $self->FETCHSIZE;
}

#=============================================================================
1983;
__END__

=head1 NAME

SNMP::Effective::VarList - Helper module for SNMP::Effective

=head1 VERSION

See SNMP::Effective

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
