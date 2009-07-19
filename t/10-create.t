#!perl

use strict;
use warnings;
use lib qw(./lib);
use SNMP::Effective;
use Log::Log4perl qw(:easy);
use Test::More tests => 17;

BEGIN {
    no warnings 'redefine';
    *SNMP::Session::get = sub {
        my($method, $obj, $host) = @{ $_[2] };
        ok($obj->can($method), "$host / SNMP::Effective can $method()");
    };
}

my $max_sessions = 2;
my @host = qw/10.1.1.2/;
my @walk = qw/sysDescr/;
my $timeout = 3;
my($effective, $host, $req);

Log::Log4perl->easy_init($ENV{'VERBOSE'} ? $TRACE : $FATAL);

$effective = SNMP::Effective->new(max_sessions => $max_sessions);

ok($effective, 'object constructed');
ok(!$effective->execute, "cannot execute without hosts");

# add
$effective->add(
    Dest_Host => \@host,
    Arg      => { Timeout => $timeout },
    CallbaCK => sub { return "test" },
    walK     => \@walk,
);

is(scalar($effective->hosts), scalar(@host), 'add two hosts');

ok($host = $effective->_shift_host, "host fetched");
ok($req = shift @$host, "request defined");
is($req->[0], "walk", "method is ok");
isa_ok($req->[1], "SNMP::VarList", "VarList");

# add with defaults
$effective->add(get => 'sysName', heap => { foo => 42 });
$effective->add(getnext => 'ifIndex');
$effective->add(dest_host => '127.0.0.1');

ok($host = $effective->_shift_host, "host with defauls fetched");
ok($req = shift @$host, "first default request defined");
is($req->[0], "get", "first default method is ok");
ok($req = shift @$host, "second default request defined");
is($req->[0], "getnext", "second default method is ok");
is_deeply($host->heap, { foo => 42 }, "default heap is set");

# dispatcher
push @host, '10.1.1.3';
$effective->add(dest_host => \@host);
ok($effective->_dispatch, "dispatcher set up hosts");
is($effective->sessions, $max_sessions, "correct number of sessions");

