#!perl 
use warnings;
use strict;

use Test::More tests => 23;

{
    ## no critic

    eval "
        use Test::Compile;
    ";
};

plan skip_all => "Test::Compile not installed" if $@;

exit if $@;

my $test = Test::Compile->new;

$test->verbose(0);

$test->all_files_ok;

my @pl = $test->all_pl_files('examples');

for (@pl){
    ok($test->pl_file_compiles($_), "$_ compiles ok");
}

#$test->done_testing;

