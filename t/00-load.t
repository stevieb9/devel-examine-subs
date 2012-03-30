#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Devel::ExamineSubs' ) || print "Bail out!\n";
}

diag( "Testing Devel::ExamineSubs $Devel::ExamineSubs::VERSION, Perl $], $^X" );

can_ok( 'Devel::ExamineSubs', 'has' );
can_ok( 'Devel::ExamineSubs', 'missing' );
can_ok( 'Devel::ExamineSubs', 'all' );
