#!/usr/bin/perl
use warnings;
use strict;

use Devel::Examine::Subs;
use Data::Dumper;

my %p = (file => 't/sample.data', engine => 'all');

my $des = Devel::Examine::Subs->new(%p);

$des->run({engine_dump => 1});

#print Dumper $cref;
