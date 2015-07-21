#!/usr/bin/perl
use warnings;
use strict;

use Devel::Examine::Subs;


my $params = {
                file => 't/sample.data', 
              };

my $des = Devel::Examine::Subs->new($params);

my $all = $des->run({engine => 'all'});

print "$_\n" for @$all;

$all = $des->all({
                file => '../t/sample.data', 
});

print scalar(@$all) . "\n";
