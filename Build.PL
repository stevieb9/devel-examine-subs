use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Devel::ExamineSubs',
    license             => 'perl',
    dist_author         => q{Steve Bertrand <steveb@cpan.org>},
    dist_version_from   => 'lib/Devel/ExamineSubs.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    meta_merge => {
        resources => {
            bugtracker => 'https://bitbucket.org/spek/devel-examinesubs/issues',
            repository => 'https://bitbucket.org/spek/devel-examinesubs',
        },
    },
    add_to_cleanup      => [ 'Devel-ExamineSubs-*' ],
    #create_makefile_pl => 'traditional',
);

$builder->create_build_script();
