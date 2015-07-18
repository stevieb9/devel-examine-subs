#!perl -T
use warnings;
use strict;

use Test::More tests => 10;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new();

{#2
    my $res = $des->missing({ file =>  't/sample.data', search => 'this' });
    ok ( $res->[0] =~ '\w+', "legacy missing() returns an array if file exists and text available" );
}
{#3
    my $res = $des->missing({ file => 't/sample.data', search => '' });
    ok ( ! $res->[0], "legacy missing() returns an empty array if file exists and text is empty string" );
}
{#4
    my $res = $des->missing({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( $res->[0], "obj->missing() returns an array if file exists and search text not found" );
}
{#5-7
    my $params = {
                    file => 't/sample.data', 
                    engine => 'missing', 
                  };

    my $des = Devel::Examine::Subs->new($params);
    
    my $missing = $des->run($params);

    ok ( ref($missing) eq 'ARRAY', "calling the 'missing' engine through run() returns an aref" );
    is ( @$missing, 0, "'missing' engine returns the proper count of subs through run()" );
    ok ( ref($missing) eq 'ARRAY', "missing engine does the right thing through run() with no search" );
}
{#8
    my $params = {
                    file => 't/sample.data', 
                    engine => 'missing', 
                    search => 'this',  
                };

    my $des = Devel::Examine::Subs->new($params);

    $missing = $des->run($params);

    is ( @$missing, 6, "'missing' engine returns the proper count of subs through run() with 'this'" );
}
{#9
     my $params = {
                    file => 't/sample.data', 
                    engine => 'missing', 
                    search => 'return',
                };

    my $des = Devel::Examine::Subs->new($params);

    $missing = $des->run($params);

    is ( @$missing, 8, "'missing' engine returns the proper count of subs through run() with 'return'" );
}
{#10
    my $params = {
                    file => 't/sample.data', 
                    engine => 'missing', 
                    search => 'asdf',
                };

    my $des = Devel::Examine::Subs->new($params);
    my $missing = $des->run();
    
    is ( @$missing, 11, "'missing' engine returns the proper count of subs through run() with 'asdf'" );
}

