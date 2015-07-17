#!perl -T

use Test::More tests => 1;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}


{
    my $p = {
        pre_filter => 'subs',
        file => 't/sample.data',
        pf_dump => 1,
    };
    my $des = Devel::Examine::Subs->new();
    $des->run($p);
    

    

}
