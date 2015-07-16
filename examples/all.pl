#!/usr/bin/perl
use warnings;
use strict;

use Devel::Examine::Subs;


my $params = {
                file => 't/sample.data', 
                engine => 'all', 
              };

my $des = Devel::Examine::Subs->new($params);

my $all = $des->run($params);

print "$_\n" for @$all;

$all = $des->all({
                file => 't/sample.data', 
                engine => 'all',
});

print scalar(@$all) . "\n";
