# You can install this projct with curl -L http://cpanmin.us | perl - https://github.com/jhthorsen/snmp-effective/archive/master.tar.gz
requires "SNMP"                   => 0;
requires "NetSNMP::default_store" => 0;
requires "Tie::Array"             => "1.00";
requires "Time::HiRes"            => "1.00";

test_requires "Test::More" => "1.30";
