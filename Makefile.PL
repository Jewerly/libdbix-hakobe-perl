use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DBIx::Hakobe',
    AUTHOR              => 'MIZUTANI Tociyuki <tociyuki@gmail.com>',
    VERSION_FROM        => 'lib/DBIx/Hakobe.pm',
    ABSTRACT_FROM       => 'lib/DBIx/Hakobe.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Base' => 0,
        'Test::Exception' => 0,
        'DBI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
