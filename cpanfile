# You can install this projct with curl -L http://cpanmin.us | perl - https://github.com/jhthorsen/snmp-effective/archive/master.tar.gz
requires "POSIX"       => "1.80";
requires "SNMP"        => 0;
requires "Tie::Array"  => "1.05";
requires "Time::HiRes" => "1.90";

test_requires "Test::More" => "1.30";
