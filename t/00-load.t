#!perl -T
use warnings;
use strict;

use Test::More tests => 20;

BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Sub' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Engine' ) || print "Bail out!\n";
    use_ok( 'PPI' ) || print "PPI can't be loaded, bailing out!\n";
    use_ok( 'Tie::File' ) || print "Tie::File can't be loaded, bailing out!\n";

}

diag( "Testing Devel::Examine::Subs $Devel::Examine::Subs::VERSION, Perl $], $^X" );

my $subs_namespace = "Devel::Examine::Subs";

can_ok( $subs_namespace, 'new' );
can_ok( $subs_namespace, 'has' );
can_ok( $subs_namespace, 'missing' );
can_ok( $subs_namespace, 'all' );

can_ok( $subs_namespace, '_file' );
can_ok( $subs_namespace, '_core' );
can_ok( $subs_namespace, '_engine' );
can_ok( $subs_namespace, '_pre_filter' );

my $sub_namespace = "Devel::Examine::Subs::Sub";

can_ok( $sub_namespace, 'new' );
can_ok( $sub_namespace, 'name' );
can_ok( $sub_namespace, 'start' );
can_ok( $sub_namespace, 'stop' );
can_ok( $sub_namespace, 'count' );

my $engine_namespace = "Devel::Examine::Subs::Engine";

can_ok( $engine_namespace, '_test' );
can_ok( $engine_namespace, '_test_print' );  
