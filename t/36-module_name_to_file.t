#!perl 
use warnings;
use strict;

use Test::More tests => 3;
use Test::Trap;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new({
                            file => 'Data::Dumper',
                          });

my $all = $des->all();

ok (@$all > 30, "using Data::Dumper as an example, file => module translates");

eval {
    $des->run({file => 'Bad::XXX'});
};

isnt ($@, undef, "{file => 'module'} with module not found croaks");



