#!perl -T

use Test::More tests => 22;

BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Sub' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Engine' ) || print "Bail out!\n";
    use_ok( 'PPI' ) || print "PPI can't be loaded, bailing out!\n";
    use_ok( 'Tie::File' ) || print "Tie::File can't be loaded, bailing out!\n";

}

diag( "Testing Devel::Examine::Subs $Devel::Examine::Subs::VERSION, Perl $], $^X" );

can_ok( 'Devel::Examine::Subs', 'new' );
can_ok( 'Devel::Examine::Subs', 'has' );
can_ok( 'Devel::Examine::Subs', 'missing' );
can_ok( 'Devel::Examine::Subs', 'all' );
can_ok( 'Devel::Examine::Subs', 'line_numbers' );

can_ok( 'Devel::Examine::Subs', 'sublist' );
can_ok( 'Devel::Examine::Subs', 'module' );
can_ok( 'Devel::Examine::Subs', '_file' );
can_ok( 'Devel::Examine::Subs', '_get' );
can_ok( 'Devel::Examine::Subs', '_subs' );
can_ok( 'Devel::Examine::Subs', '_objects' );

can_ok( 'Devel::Examine::Subs::Sub', 'new' );
can_ok( 'Devel::Examine::Subs::Sub', 'name' );
can_ok( 'Devel::Examine::Subs::Sub', 'start' );
can_ok( 'Devel::Examine::Subs::Sub', 'stop' );
can_ok( 'Devel::Examine::Subs::Sub', 'count' );

can_ok( 'Devel::Examine::Subs::Engine', '_test' );
