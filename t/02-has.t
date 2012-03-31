#!perl -T

use Test::More tests => 7;
use Test::Exception;

BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{
    eval { Devel::Examine::Subs->has({ file => 'badfile.none', search => 'text' }) };
    ok ( $@ =~ /Invalid file supplied/, "has() dies with error if file not found" );
}
{
    my @res = Devel::Examine::Subs->has({ file => 't/sample.data', search => 'this' });
    ok ( $res[0] =~ '\w+', "has() returns an array if file exists and text available" );
}
{
    my @res = Devel::Examine::Subs->has({ file => 't/sample.data', search => '' });
    ok ( ! @res, "has() returns an empty array if file exists and text is empty string" );
}
{
    my @res = Devel::Examine::Subs->has({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( ! @res, "has() returns an empty array if file exists and search text not found" );
}
{    
    my $res = Devel::Examine::Subs->has({ file => 't/sample.data', search => 'this' });
    ok ( ref \$res eq 'SCALAR', "has() returns a scalar when called in scalar context" );
}
{
    my $res = Devel::Examine::Subs->has({ file => 't/sample.data', search => 'this' });
    is ( $res, 2, "has() returns the proper count of names when data is found" );
}

