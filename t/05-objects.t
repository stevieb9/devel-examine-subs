#!perl -T
use warnings;
use strict;

use Test::More tests => 5;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $file = 't/sample.data';

my $p = {
    file => $file, 
    engine => 'objects',
    pre_filter => 'subs',
    #pre_filter_dump => 1,
};

my $des = Devel::Examine::Subs->new($p);

my $objects = $des->run();

for my $o (@$objects){
    if ($o->name() eq 'eight'){
        is ($o->start(), 48, "sub eight starts at the right line");
        is ($o->end(), 50, "sub eight ends at the right line");
    } 
    if ($o->name() eq 'two'){
        is ($o->start(), 16, "sub two starts at the right line");
        is ($o->end(), 20, "sub two starts at the right line");
    } 
}

#print Dumper $des->objects();
