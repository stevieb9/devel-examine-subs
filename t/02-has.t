#!perl -T

use Test::More tests => 7;
use Test::Exception;

BEGIN {
    use_ok( 'Devel::ExamineSubs' ) || print "Bail out!\n";
}

{
    eval { Devel::ExamineSubs->has( 'badfile.none', 'text' ) };
    ok ( $@ =~ /Invalid file supplied/, "has() dies with error if file not found" );
}
{
    my @res = Devel::ExamineSubs->has( 't/sample.data', 'this' );
    ok ( $res[0] =~ '\w+', "has() returns an array if file exists and text available" );
}
{
    my @res = Devel::ExamineSubs->has( 't/sample.data', '' );
    ok ( ! @res, "has() returns an empty array if file exists and text is empty string" );
}
{
    my @res = Devel::ExamineSubs->has( 't/sample.data', 'asdfasdf' );
    ok ( ! @res, "has() returns an empty array if file exists and search text not found" );
}
{
    my $res = Devel::ExamineSubs->has( 't/sample.data', 'this');
    ok ( ref \$res eq 'SCALAR', "has() returns a scalar when called in scalar context" );
}
{
    my $res = Devel::ExamineSubs->has( 't/sample.data', 'this' );
    is ( $res, 2, "has() returns the proper count of names when data is found" );
}

