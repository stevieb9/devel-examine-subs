#!perl -T

use Test::More tests => 11;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{#2
    eval { Devel::Examine::Subs->missing({ file => 'badfile.none', search => 'text' }) };
    ok ( $@ =~ /Invalid file supplied/, "missing() dies with error if file not found" );
}
{#3
    my @res = Devel::Examine::Subs->missing({ file =>  't/sample.data', search => 'this' });
    ok ( $res[0] =~ '\w+', "missing() returns an array if file exists and text available" );
}
{#4
    my @res = Devel::Examine::Subs->missing({ file => 't/sample.data', search => '' });
    ok ( ! @res, "missing() returns an empty array if file exists and text is empty string" );
}
{#5
    my @res = Devel::Examine::Subs->missing({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( @res, "missing() returns an array if file exists and search text not found" );
}
{#6
    my $res = Devel::Examine::Subs->missing({ file => 't/sample.data', search => 'this' });
    ok ( ref \$res eq 'SCALAR', "missing() returns a scalar when called in scalar context" );
}
{#7
    my $res = Devel::Examine::Subs->missing({ file => 't/sample.data', search => 'this' });
    is ( $res, 2, "missing() returns the proper count of names when data is found" );
}

my $des = Devel::Examine::Subs->new();

{#8
    my @res = $des->missing({ file =>  't/sample.data', search => 'this' });
    ok ( $res[0] =~ '\w+', "obj->missing() returns an array if file exists and text available" );
}
{#9
    my @res = $des->missing({ file => 't/sample.data', search => '' });
    ok ( ! @res, "obj->missing() returns an empty array if file exists and text is empty string" );
}
{#10
    my @res = $des->missing({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( @res, "obj->missing() returns an array if file exists and search text not found" );
}
{#11
    my $res = $des->missing({ file => 't/sample.data', search => 'this' });
    ok ( ref \$res eq 'SCALAR', "obj->missing() returns a scalar when called in scalar context" );
}

