#!perl -T

use Test::More tests => 5;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}
{#2
    my $des = Devel::Examine::Subs->new();
    my @res = $des->module({ module => 'Data::Dumper' });
    is ( ref(\@res), 'ARRAY', "module() properly returns an aref" );
}
{#3
    my $des = Devel::Examine::Subs->new();

    my @res = $des->module({ module => '' });
    is( ref(\@res), 'ARRAY' , "module() an aref if no module is sent in" );
    is( $res[0], undef , "module() an empty aref if no module is sent in" );
}
{#4-5
    my $des = Devel::Examine::Subs->new();

    my $res = $des->module();
    is( $res[0], undef, "module() returns an empty array ref if no params are passed in" );
}
