#!perl
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 2;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new(file => 't/sample.data');

my $end = $des->run({pre_filter => 'subs && end_of_last_sub'});

is ($end, 50, "pre_filter 'end_of_last_sub' properly returns last line num in last sub in file" );
