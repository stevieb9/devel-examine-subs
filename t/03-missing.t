#!perl -T

use Test::More tests => 7;
use Test::Exception;

BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{
    eval { Devel::Examine::Subs->missing({ file => 'badfile.none', search => 'text' }) };
    ok ( $@ =~ /Invalid file supplied/, "missing() dies with error if file not found" );
}
{
    my @res = Devel::Examine::Subs->missing({ file =>  't/sample.data', search => 'this' });
    ok ( $res[0] =~ '\w+', "missing() returns an array if file exists and text available" );
}
{
    my @res = Devel::Examine::Subs->missing({ file => 't/sample.data', search => '' });
    ok ( ! @res, "missing() returns an empty array if file exists and text is empty string" );
}
{
    my @res = Devel::Examine::Subs->missing({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( @res, "missing() returns an array if file exists and search text not found" );
}
{
    my $res = Devel::Examine::Subs->missing({ file => 't/sample.data', search => 'this' });
    ok ( ref \$res eq 'SCALAR', "missing() returns a scalar when called in scalar context" );
}
{
    my $res = Devel::Examine::Subs->missing({ file => 't/sample.data', search => 'this' });
    is ( $res, 3, "missing() returns the proper count of names when data is found" );
}

