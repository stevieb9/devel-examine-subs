#!perl
use warnings;
use strict;

use Test::More tests => 6;

use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}
{#2
    my $des = Devel::Examine::Subs->new();
    my @res = $des->module({ module => 'Data::Dumper' });
    is ( ref(\@res), 'ARRAY', "module() properly returns an aref" );
}
{#3-4
    my $des = Devel::Examine::Subs->new();

    my $res = $des->module({ module => '' });
    is( ref($res), 'ARRAY' , "module() an aref if no module is sent in" );
    is( $res->[0], undef , "module() an empty aref if no module is sent in" );
}
{#5
    my $des = Devel::Examine::Subs->new();

    my $res = $des->module();
    is( $res->[0], undef, "module() returns an empty array ref if no params are passed in" );
}
{#6
    my $des = Devel::Examine::Subs->new({module => 'Data::Dumper'});

    my $res = $des->module();
    print Dumper $res;
    my $ok = grep /Dumper/, @$res;

    ok( $ok, "module() returns an array of sub names" );
}
