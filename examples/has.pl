#!/usr/bin/perl
use warnings;
use strict;

use Devel::Examine::Subs;

my $des = Devel::Examine::Subs->new($params);

my $params = {
                file => 't/sample.data', 
                engine => 'has', 
                search => 'this',
              };


my $has = $des->run($params);

print "$_\n" for @$has;

$has = $des->has({
                file => 't/sample.data', 
                engine => 'has', 
                search => 'this',
});

print scalar(@$has) . "\n";
