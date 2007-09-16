#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SNMP::Effective' );
}

diag( "Testing SNMP::Effective $SNMP::Effective::VERSION, Perl $], $^X" );
