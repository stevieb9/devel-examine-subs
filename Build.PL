use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Devel::Examine::Subs',
    license             => 'perl',
    dist_author         => q{Steve Bertrand <steveb@cpan.org>},
    dist_version_from   => 'lib/Devel/Examine/Subs.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    meta_merge => {
        resources => {
            bugtracker => 'https://bitbucket.org/spek/devel-examine-subs/issues',
            repository => 'https://bitbucket.org/spek/devel-examine-subs',
        },
    },
    add_to_cleanup      => [ 'Devel-Examine::Subs-*' ],
    #create_makefile_pl => 'traditional',
);

$builder->create_build_script();
