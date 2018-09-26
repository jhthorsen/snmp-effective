package SNMP::Effective::VarList;
use warnings;
use strict;

use Carp 'confess';
use SNMP;
use Tie::Array;

use base 'Tie::StdArray';

sub PUSH {
  my $self = shift;
  my @args = @_;

LIST:
  for my $list (@args) {
    confess "A list of array-refs are required to push()" unless ref $list eq 'ARRAY';
    confess "Each array-ref to push() must have more than one element" unless @$list > 1;
    confess "The first element in the array-ref to push() must exist in \%SNMP::Effective::Dispatch::METHOD"
      unless $SNMP::Effective::Dispatch::METHOD{$list->[0]};

    my $method = $list->[0];
    my $i      = 0;
    my @varlist;

  OID:
    for my $oid (@$list) {
      next unless $i++;    # skip the first element, containing the method

      if (ref $oid eq '') {    # create varbind
        $oid = SNMP::Varbind->new([$oid]);
      }
      if (ref $oid eq 'SNMP::Varbind') {    # append varbind
        push @varlist, $oid;
        next OID;
      }
      if (ref $oid eq 'SNMP::VarList') {    # append varlist
        push @varlist, @$oid;
        next OID;
      }
    }

    if (@varlist) {
      push @$self, [$method, SNMP::VarList->new(@varlist)];
    }
  }

  return $self->FETCHSIZE;
}

1;

=encoding utf8

=head1 NAME

SNMP::Effective::VarList - Helper module for SNMP::Effective::Host

=head1 DESCRIPTION

Thist module allows oid/oid-methods to be specified in different ways.

=head1 SYNOPSIS

  use SNMP::Effective::VarList;
  tie @varlist, 'SNMP::Effective::VarList';

  push @varlist, [$method1, $oid1], [$method2, $oid2];
  push @varlist, [$method1, $Varbind_obj1], [$method2, $Varbind_obj2];
  push @varlist, [$method1, $VarList_obj1], [$method2, $VarList_obj2];

=head1 SEE ALSO

See L<SNMP::Effective>

=cut
