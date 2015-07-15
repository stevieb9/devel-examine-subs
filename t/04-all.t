#!perl -T

use Test::More tests => 6;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new();

{#8
    my @res = $des->all({ file => 't/sample.data', search => '' });
    ok ( @res, "obj->all() returns an array if file exists and text is empty string" );
}
{#9
    my @res = $des->all({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( @res, "obj->all() returns an array if file exists and search text not found" );
}
{#10
    my $res = $des->all({ file => 't/sample.data' });
    ok ( ref \$res eq 'SCALAR', "obj->all() returns a scalar when called in scalar context" );
}
{#11
    my $res = $des->all({ file => 't/sample.data', search => 'this' });
    is ( $res, 8, "obj->all() returns the proper count of names when data is found" );
}
{#12
    my $res = $des->all({ file => 't/sample.data' });
    is ( $res, 8, "obj->all() does the right thing with no text param" );
}

