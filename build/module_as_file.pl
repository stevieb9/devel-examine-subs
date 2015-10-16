#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;

my $des = Devel::Examine::Subs->new(file => 'Data::Dump');

my $all = $des->all;

print Dumper $all;
