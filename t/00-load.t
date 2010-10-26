use lib qw(lib);
use Test::More;
plan tests => 5;
use_ok('SNMP::Effective');
use_ok('SNMP::Effective::Dispatch');
use_ok('SNMP::Effective::Host');
use_ok('SNMP::Effective::HostList');
use_ok('SNMP::Effective::VarList');
