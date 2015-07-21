#!/usr/bin/perl
use warnings;
use strict;

use Devel::Examine::Subs;

my $params = {
                file => '../t/sample.data', 
                engine => 'has', 
                search => 'this',
                core_dump => 1,
              };

my $des = Devel::Examine::Subs->new($params);

my $has = $des->run($params);

print "$_\n" for @$has;

$has = $des->has({
                file => '../t/sample.data', 
                search => 'this',
});

print scalar(@$has) . "\n";
