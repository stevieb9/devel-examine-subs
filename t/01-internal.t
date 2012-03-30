#!perl -T

# for testing internal subs, either directly,
# or through an accessor

use Test::More tests => 3;
use Test::Exception;

BEGIN {
    use_ok( 'Devel::ExamineSubs' ) || print "Bail out!\n";
}
{
    eval { Devel::ExamineSubs->has( 'badfile.none', 'text' ) };
    ok ( $@ =~ /Invalid file supplied/, "has() dies with error if file not found" );
}
       
{
    eval { Devel::ExamineSubs->has( 'text' ) };
    like ( $@, qr/Invalid number of params/, "module dies with error if no file passed in" );
}
