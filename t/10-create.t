#!perl

use strict;
use warnings;
use lib qw(./lib);
use Test::More tests => 7;

BEGIN {
    use_ok( 'SNMP::Effective' );
    no warnings 'redefine';
    *SNMP::_new_session = sub { 42 };
}

my $effective = SNMP::Effective->new;
my @host      = qw/10.1.1.2 10.1.1.3/;
my @walk      = qw/sysDescr/;
my $timeout   = 3;
my($host, $req);

ok($effective, 'object constructed');

$effective->add(
    Dest_Host => \@host,
    Arg      => { Timeout => $timeout },
    CallbaCK => sub { return "test" },
    walK     => \@walk,
);

is(scalar($effective->hosts), scalar(@host), 'add two hosts');

ok($host = $effective->shift_host, "host fetched");
ok($req = shift @$host, "request defined");
is($req->[0], "walk", "method is ok");
isa_ok($req->[1], "SNMP::VarList", "VarList");

