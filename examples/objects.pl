#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;

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
    print $o->name() . "\n";
}

print Dumper $des->objects();
