#!perl -T

use Test::More tests => 11;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new();

{#2
    my $res = $des->all({ file => 't/sample.data', search => '' });
    ok ( ref($res) eq 'ARRAY', "obj->all() returns an array ref if file exists and text is empty string" );
}
{#3
    my $res = $des->all({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( @$res, "obj->all() returns an array ref if file exists and search text not found" );
}
{#4
    my $res = $des->all({ file => 't/sample.data' });
    ok ( ref($res) eq 'ARRAY', "obj->all() returns an aref when called in scalar context" );
}
{#5
    my $res = $des->all({ file => 't/sample.data', search => 'thifs' });
    is ( @$res, 11, "obj->all() returns the proper count of names when data is found" );
}
{#6
    my $res = $des->all({ file => 't/sample.data' });
    is ( @$res, 11, "obj->all() does the right thing with no search param" );
}
{#7
    my $params = {
                    file => 't/sample.data', 
                    engine => 'all', 
                  };

    my $des = Devel::Examine::Subs->new($params);
    
    my $all = $des->run($params);

    ok ( ref($all) eq 'ARRAY', "calling the 'all' engine through run() returns an aref" );
    is ( @$all, 11, "'all' engine returns the proper count of subs through run()" );
    ok ( ref($all) eq 'ARRAY', "all engine does the right thing through run() with no search" );
}
{#8

    my $des = Devel::Examine::Subs->new($params);

    $all = $des->all({
                file => 't/sample.data', 
                engine => 'all',
            });

    ok ( ref($all) eq 'ARRAY', "legacy all() does the right thing sending {engine=>'all'}" );
}
{#9

    my $des = Devel::Examine::Subs->new($params);

    $all = $des->all({file => 't/sample.data'});

    ok ( ref($all) eq 'ARRAY', "legacy all() sets the engine param properly" );
}

