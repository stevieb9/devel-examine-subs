#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Devel::ExamineSubs' ) || print "Bail out!\n";
}

diag( "Testing Devel::ExamineSubs $Devel::ExamineSubs::VERSION, Perl $], $^X" );
