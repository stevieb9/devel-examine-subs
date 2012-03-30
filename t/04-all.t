#!perl -T

use Test::More tests => 7;
use Test::Exception;

BEGIN {
    use_ok( 'Devel::ExamineSubs' ) || print "Bail out!\n";
}

{
    my @res = Devel::ExamineSubs->all( 't/sample.data', 'this' );
    ok ( $res[0] =~ '\w+', "all() returns an array" );
}
{
    my @res = Devel::ExamineSubs->all( 't/sample.data', '' );
    ok ( @res, "all() returns an array if file exists and text is empty string" );
}
{
    my @res = Devel::ExamineSubs->all( 't/sample.data', 'asdfasdf' );
    ok ( @res, "all() returns an array if file exists and search text not found" );
}
{
    my $res = Devel::ExamineSubs->all( 't/sample.data', 'this');
    ok ( ref \$res eq 'SCALAR', "all() returns a scalar when called in scalar context" );
}
{
    my $res = Devel::ExamineSubs->all( 't/sample.data', 'this' );
    is ( $res, 5, "all() returns the proper count of names when data is found" );
}
{
    my $res = Devel::ExamineSubs->all( 't/sample.data' );
    is ( $res, 5, "all() does the right thing with no text param" );
}

