#!perl -T

use Test::More tests => 11;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new();

{#2
    eval { Devel::Examine::Subs->has({ file => 'badfile.none', search => 'text' }) };
    ok ( $@ =~ /Invalid file supplied/, "has() dies with error if file not found" );
}
{#3
    my @res = Devel::Examine::Subs->has({ file => 't/sample.data', search => 'this' });
    ok ( $res[0] =~ '\w+', "has() returns an array if file exists and text available" );
}
{#4
    my @res = Devel::Examine::Subs->has({ file => 't/sample.data', search => '' });
    ok ( ! @res, "has() returns an empty array if file exists and text is empty string" );
}
{#5
    my @res = Devel::Examine::Subs->has({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( ! @res, "has() returns an empty array if file exists and search text not found" );
}
{#6    
    my $res = Devel::Examine::Subs->has({ file => 't/sample.data', search => 'this' });
    ok ( ref \$res eq 'SCALAR', "has() returns a scalar when called in scalar context" );
}
{#7
    my $res = Devel::Examine::Subs->has({ file => 't/sample.data', search => 'this' });
    is ( $res, 6, "has() returns the proper count of names when data is found" );
}
{#8
    my @res = $des->has({ file => 't/sample.data', search => 'this' });
    ok ( $res[0] =~ '\w+', "obj->has() returns an array if file exists and text available" );
}
{#9
    my @res = $des->has({ file => 't/sample.data', search => '' });
    ok ( ! @res, "obj->has() returns an empty array if file exists and text is empty string" );
}
{#10
    my @res = $des->has({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( ! @res, "obj->has() returns an empty array if file exists and search text not found" );
}
{#11    
    my $res = $des->has({ file => 't/sample.data', search => 'this' });
    ok ( ref \$res eq 'SCALAR', "obj->has() returns a scalar when called in scalar context" );
}

