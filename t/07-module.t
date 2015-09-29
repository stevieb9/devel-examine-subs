#!perl
use warnings;
use strict;

use Test::More tests => 10;

use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}
{#2
    my $des = Devel::Examine::Subs->new();
    my @res = $des->module( module => 'Data::Dumper' );
    is ( ref(\@res), 'ARRAY', "module() properly returns an aref" );
}
{#3-4
    my $des = Devel::Examine::Subs->new();

    my $res = $des->module( module => '' );
    is( ref($res), 'ARRAY' , "module() an aref if no module is sent in" );
    is( $res->[0], undef , "module() an empty aref if no module is sent in" );
}
{#5
    my $des = Devel::Examine::Subs->new();

    my $res = $des->module();
    is( $res->[0], undef, "module() returns an empty array ref if no params are passed in" );
}
{#6
    my $des = Devel::Examine::Subs->new(module => 'Data::Dumper');

    my $res = $des->module();
#    print Dumper $res;
    my $ok = grep /Dumper/, @$res;

    ok( $ok, "module() returns an array of sub names" );
}
{#7
    my $des = Devel::Examine::Subs->new(module => 'X:Xxx');

    eval { my $res = $des->module(); };

    ok( $@ =~ qr/Module X:Xxx not found/, "Error returned if module() can't find the module" );
}
{#8
    # check for string param

    my $des = Devel::Examine::Subs->new;

    my $res;
    eval { $res = $des->module('Data::Dumper'); };

    ok (! $@, "module() string param works");

    is (ref $res, 'ARRAY', "module() with string param returns aref");

    my $thing = grep /\bDump\b/, @$res;

    is ($thing, 1, "module() with string param has expected data");

}
