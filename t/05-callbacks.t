#!perl

use strict;
use warnings;
use lib qw(./lib);
use SNMP::Effective::Callbacks;
use Test::More tests => 1;

my $effective = SNMP::Effective->new;
my $methods = $effective->meta->snmp_callback_map;

can_ok($effective, map { "_cb_$_" } keys %$methods);

