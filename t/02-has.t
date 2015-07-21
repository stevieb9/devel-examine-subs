#!perl 
use warnings;
use strict;

use Test::More tests => 25;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new({file => 't/sample.data'});

{#2
    my $des2 = Devel::Examine::Subs->new();
    eval { $des2->has({ file => 'badfile.none'}) };
    ok ( $@ =~ /Invalid file supplied/, "new() dies with error if file not found" );
}

{#3
    my $des = Devel::Examine::Subs->new();
    my $res = $des->has({ file => 't/sample.data', search => 'this' });
    ok ( $res->[0] =~ '\w+', "has() returns an array ref file exists and text available" );
}
{#4
    my $res = $des->has({ file => 't/sample.data', search => 'this' });
    ok ( $res->[0] =~ '\w+', "obj->has() returns an array if file exists and text available" );
}
{#5
    my $res = $des->has({ file => 't/sample.data', search => '' });
    print "$_\n" for @$res;
    ok ( ! $res->[0], "obj->has() returns an empty array if file exists and text is empty string" );
}
{#6
    my $res = $des->has({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( ! $res->[0], "obj->has() returns an empty array if file exists and search text not found" );
}
{#7    
    my $res = $des->has({ file => 't/sample.data', search => 'this' });
    like ( $res, qr/ARRAY/, "obj->has() returns an aref " );
}
{#8
    my $res = $des->lines({ file => 't/sample.data', search => 'this' });
    like ( $res, qr/HASH/, "lines() returns a hash" );
}
{#9-13
    my $res = $des->lines({ file => 't/sample.data', search => 'this', lines => 1 });
    for my $key (keys %$res){
        ok (ref($res->{$key}) eq 'ARRAY', "lines()  hash contains array refs" );
    }
}
{#14
    my $des = Devel::Examine::Subs->new({file => 't/sample.data'});
    my $res = $des->has({ search => 'this' });
    ok ( $res->[0] =~ '\w+', "has() returns an array if new() takes 'file' and has() doesn't" );
}
{#15-17
    my $params = {
                    file => 't/sample.data', 
                    engine => 'all', 
                  };

    my $des = Devel::Examine::Subs->new($params);
    
    my $has = $des->run($params);

    ok ( ref($has) eq 'ARRAY', "calling the 'has' engine through run() returns an aref" );
    is ( @$has, 11, "'has' engine returns the proper count of subs through run()" );
    ok ( ref($has) eq 'ARRAY', "has engine does the right thing through run() with no search" );
}
{#18

    my $des = Devel::Examine::Subs->new();

    my $has = $des->has({
                file => 't/sample.data', 
                engine => 'all',
                search => 'this',
            });

    ok ( ref($has) eq 'ARRAY', "legacy all() does the right thing sending {engine=>'all'}" );
}
{#17-20

    my $des = Devel::Examine::Subs->new();

    my $has = $des->has({file => 't/sample.data', search => 'this'});

    is ( @$has, 5, "legacy has() sets the engine param properly" );
    is ( @$has, 5, "legacy has() gets the proper number of find when searching" );
}

{
    my $params = { file => 't/test', search => 'this' };

    my $des = Devel::Examine::Subs->new($params);

    my $ret = $des->has();

    is (keys %$ret, 2, "has() directory has the correct number of keys" );

    for (keys %$ret){
        ok (ref $ret->{$_} eq 'ARRAY', "has() directory keys contain arefs" );
        is (@{$ret->{$_}}, 5, "has() directory keys have the correct number of elements" );
    }
}
