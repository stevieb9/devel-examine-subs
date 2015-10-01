#!perl 
use warnings;
use strict;

use Test::More;

{
    ## no critic

    eval "
        use Test::Compile 0.12.0;
    ";
};

plan skip_all => "Test::Compile not installed" if $@;

exit if $@;

plan tests => 15;
my $test = Test::Compile->new;

$test->verbose(0);

$test->all_files_ok;

my @pl = $test->all_pl_files('examples');

for (@pl){
    ok($test->pl_file_compiles($_), "$_ compiles ok");
}

#$test->done_testing;

