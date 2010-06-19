#!/usr/bin/env perl
use lib qw(lib);
use Test::More;
plan tests => 6;
use_ok('SNMP::Effective');
use_ok('SNMP::Effective::Dispatch');
use_ok('SNMP::Effective::Host');
use_ok('SNMP::Effective::HostList');
use_ok('SNMP::Effective::Logger');
use_ok('SNMP::Effective::VarList');
