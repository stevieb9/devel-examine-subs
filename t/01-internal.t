#!perl -T

# for testing internal subs, either directly,
# or through an accessor

use Test::More tests => 3;
use Test::Exception;

BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}
{
    eval { Devel::Examine::Subs->has({ file => 'badfile.none', search => 'text', }) };
    like ( $@, qr/Invalid file supplied/, "has() dies with error if file not found" );
}
{
    my $des = Devel::Examine::Subs->new();
    is ( ref $des, 'Devel::Examine::Subs', "new() instantiates a new blessed object" );
}
