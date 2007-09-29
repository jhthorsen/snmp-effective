#!perl -T

use strict;
use warnings;
use lib qw(./lib);
use Test::More tests => 9;

BEGIN {
	use_ok( 'SNMP::Effective' );
}

my $effective = SNMP::Effective->new;
my @host      = qw/10.1.1.2 10.1.1.3/;
my @walk      = qw/sysDescr/;
my $timeout   = 3;

ok($effective, 'object not constructed');


$effective->add(
    Dest_Host => \@host,
    Arg      => { Timeout => $timeout },
    CallbaCK => sub { return "test" },
    walK     => \@walk,
);

is(scalar($effective->hostlist), scalar(@host), 'Added two hosts');

my $host = shift @{ $effective->hostlist };
my $req  = shift @$host;

### create session
$$host = $effective->_create_session($host);

is(ref $$host, "SNMP::Session", "SNMP session created");
is($req->[0], "walk", "method is ok");
is(ref $req->[1], "SNMP::VarList", "VarList defined");

is(SNMP::Effective::match_oid("1.3.6.10", "1.3.6"), 10, "oid match");
is(SNMP::Effective::make_name_oid("1.3.6.1.2.1.1.1"), "sysDescr", "name match numeric");
is(SNMP::Effective::make_numeric_oid("sysDescr"), ".1.3.6.1.2.1.1.1", "numeric match numeric");

