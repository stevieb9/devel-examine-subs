#!perl
use warnings;
use strict;

use Carp;
use Test::More tests => 40;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my %params = (
                file => 't/sample.data',
                copy => 't/search_replace.data',
                pre_filter => ['file_lines_contain', 'subs', 'objects'],
                engine => 'search_replace',
#                engine_dump => 1,
                search => 'this',
                replace => 'that',
              );

my $des = Devel::Examine::Subs->new(%params);

my $struct = $des->run(\%params);

ok ( ref($struct) eq 'ARRAY', "search_replace engine returns an aref" );
ok ( ref($struct->[0]) eq 'ARRAY', "elems of search_replace return are arefs" );
is ( @{$struct->[0]}, 2, "only two elems in each elem in search_replace return" );

for (0..4){
    is (@{$struct->[$_]}, 2, "all elems in search_replace return contain 2 elems" );
    ok ($struct->[$_][0] =~ /this/, "first elem of each elem in s_r contains search" );
    ok ($struct->[$_][1] =~ /that/, "first elem of each elem in s_r contains replace" );
}

delete $params{engine};
delete $params{pre_filter};

my $m_struct = $des->search_replace(%params);

ok ( ref($m_struct) eq 'ARRAY', "search_replace() returns an aref" );
ok ( ref($m_struct->[0]) eq 'ARRAY', "elems of search_replace() return are arefs" );
is ( @{$m_struct->[0]}, 2, "only two elems in each elem in search_replace() return" );

for (0..4){
    is (@{$m_struct->[$_]}, 2, "all elems in search_replace() return contain 2 elems" );
    ok ($m_struct->[$_][0] =~ /this/, "first elem of each elem in s_r() contains search" );
    ok ($m_struct->[$_][1] =~ /that/, "first elem of each elem in s_r() contains replace" );
}

{

    undef %params;

    my $des = Devel::Examine::Subs->new(%params);

    eval {
        $des->search_replace(%params);
    };

    like ($@, qr/without specifying a file/, "search_replace() croaks if no file is sent in" );

    eval {
        $params{file} = 't/sample.data';
        $des->search_replace(%params);
    };

    like ($@, qr/without specifying a search term/, "search_replace() croaks if no search term is sent in" );

    eval {
        $params{file} = 't/sample.data';
        $params{search} = 'this';

        $des->search_replace(%params);
    };

    like ($@, qr/without specifying a replace term/, "search_replace() croaks if no replace term is sent in" );

}
