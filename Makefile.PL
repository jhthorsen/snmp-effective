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
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SNMP-Effective-*' },
);
