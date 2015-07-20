#!perl -T
use warnings;
use strict;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Devel::Examine::Subs::Sub' ) || print "Bail out!\n";
}

