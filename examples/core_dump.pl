#!/usr/bin/perl
use warnings;
use strict;

use Devel::Examine::Subs;

my $des = Devel::Examine::Subs->new({ engine => 'all', file => 't/sample.data', engine_dump => 1, });

$des->run();
