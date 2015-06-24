#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

diag( "Testing Devel::Examine::Subs $Devel::Examine::Subs::VERSION, Perl $], $^X" );

can_ok( 'Devel::Examine::Subs', 'has' );
can_ok( 'Devel::Examine::Subs', 'missing' );
can_ok( 'Devel::Examine::Subs', 'all' );
can_ok( 'Devel::Examine::Subs', 'new' );
can_ok( 'Devel::Examine::Subs', 'line_numbers' );
