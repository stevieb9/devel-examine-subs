#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;

my $file = 't/sample.data';

my %p = (
    file => $file, 
    #engine => 'objects',
    post_proc => ['subs', 'objects'],
    post_proc_dump => 2,
);

my $des = Devel::Examine::Subs->new(%p);

my $objects = $des->run();

for my $o (@$objects){
    print $o->name() . "\n";
}

print Dumper $des->objects();
