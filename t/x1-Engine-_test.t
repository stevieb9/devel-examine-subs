#!perl -T

use Test::More tests => 2;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs::Engine' ) || print "Bail out!\n";
}
{#2
    my $engine_return = Devel::Examine::Subs::Engine->_test();
    is ( ref($engine_return), 'HASH', "_test engine returns a hashref" );
}
{#3
}
