#!perl -T
use warnings;
use strict;

use Test::More tests => 2;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new({
                            file => 't/sample.data',
                            engine => '_test_bad',
                          });

eval { $des->run(); };
like ( $@, qr/Undefined subroutine/, "we confess properly if engine dt has a mistyped func name as val" );

