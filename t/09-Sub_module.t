#!perl
use warnings;
use strict;

use Test::More tests => 483;

BEGIN {
    use_ok( 'Devel::Examine::Subs::Sub' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new(file => 'lib/Devel/Examine/Subs.pm');

{
    my $subs = $des->objects;

    for (@$subs){
        can_ok( $_, 'name' );
        can_ok( $_, 'start' );
        can_ok( $_, 'end' );
        can_ok( $_, 'line_count' );
        can_ok( $_, 'code' );
        can_ok( $_, 'lines' );
    }
}

{
    my $href = $des->objects(objects_in_hash => 1);

    for (keys %$href){
        is (
            ref $href->{$_}, 
            'Devel::Examine::Subs::Sub', 
            "each item in hash is a Sub obj"
        );
    }

    for (keys %$href){
        can_ok( $href->{$_}, 'name' );
        can_ok( $href->{$_}, 'start' );
        can_ok( $href->{$_}, 'end' );
        can_ok( $href->{$_}, 'line_count' );
        can_ok( $href->{$_}, 'code' );
        can_ok( $href->{$_}, 'lines' );
    }
}
