#!perl

use strict;
use warnings;
use lib qw(./lib);
use Test::More tests => 7;

BEGIN {
    use_ok('SNMP::Effective::Host');
}

my $addr = "127.0.0.1";
my $host = SNMP::Effective::Host->new(
               address => $addr,
               callback => sub { 42 },
           );

is_deeply($host->arg, {
    Version   => '2c',
    Community => 'public',
    Timeout   => 1e6,
    Retries   => 2
}, "args ok");

is($host->address, $addr, "object is constructed");
is("$host", $addr, "address overload");
is(int(@$host), 0, "varbind overloaded");
is($host->(), 42, "callback overloaded");
isa_ok($$host, "SNMP::Session", "session");

