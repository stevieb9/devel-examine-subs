#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;

my $file = 't/sample.data';

my $des = Devel::Examine::Subs->new(file => $file, cache => 1);

$des->all;
$des->all;
$des->all(core_dump => 1);

