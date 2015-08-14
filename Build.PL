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
    configure_requires => {
        'Module::Build' => 0,
    },
    requires => {
        'Carp' => 0,
        'Data::Compare' => 0,
        'Data::Dumper' => 0,
        'File::Find' => 0,
        'perl' => 5.006,
        'PPI' => 0,
        'Symbol' => 0,
        'Tie::File' => 0,
        'Test::Trap' => 0,
    },
    meta_merge => {
        resources => {
            bugtracker => 'https://bitbucket.org/spek/devel-examine-subs/issues',
            repository => 'https://bitbucket.org/spek/devel-examine-subs',
        },
    },
    add_to_cleanup      => [ 'Devel-Examine::Subs-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
