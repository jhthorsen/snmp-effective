use inc::Module::Install;

name     q(SNMP-Effective);
all_from q(lib/SNMP/Effective.pm);

requires q(POSIX) => 1.0;
requires q(SNMP) => 5.0;
requires q(Moose) => 0.80;
requires q(MooseX::AttributeHelpers) => 0.20;
requires q(Log::Log4perl) => 0;

test_requires q(Test::More) => 0;

no_index      q(examples);

auto_install;
WriteAll;
