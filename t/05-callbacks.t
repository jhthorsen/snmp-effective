#!perl

use strict;
use warnings;
use lib qw(./lib);
use SNMP::Effective;
use Test::More tests => 1;

my $effective = SNMP::Effective->new;
my $methods = $effective->_method_map;

can_ok($effective, keys %$methods);

