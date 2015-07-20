#!perl -T
use warnings;
use strict;

use Test::More tests => 19;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $params = {
                file => 't/sample.data',
                copy => 't/inject_after.data',
                pre_filter => 'subs && objects',
                engine => 'inject_after',
                search => 'this',
                code => ['# comment line one', '# comment line 2' ],
              };

my $des = Devel::Examine::Subs->new($params);

my $struct = $des->run();

ok ( ref($struct) eq 'ARRAY', "search_replace engine returns an aref" );
ok ( ref($struct->[0]) eq 'ARRAY', "elems of search_replace return are arefs" );
is ( @{$struct->[0]}, 2, "only two elems in each elem in search_replace return" );

for (0..4){
    is (@{$struct->[$_]}, 2, "all elems in search_replace return contain 2 elems" );
    ok ($struct->[$_][0] =~ /this/, "first elem of each elem in s_r contains search" );
    ok ($struct->[$_][1] =~ /that/, "first elem of each elem in s_r contains replace" );
}
