use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SNMP::Effective',
    AUTHOR              => 'Jan Henning Thorsen <pm@flodhest.net>',
    VERSION_FROM        => 'lib/SNMP/Effective.pm',
    ABSTRACT_FROM       => 'lib/SNMP/Effective.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'SNMP'          => 0,
        'Time::HiRes'   => 0,
        'Log::Log4perl' => 0,
        'Tie::Array'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SNMP-Effective-*' },
    realclean           => { FILES => 'Makefile.old' },
);
