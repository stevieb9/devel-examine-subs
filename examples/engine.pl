#!/usr/bin/perl
use warnings;
use strict;

use Devel::Examine::Subs;
use Data::Dumper;

my $p = {file=>'t/sample.data', pre_filter => 'subs'};

my $des = Devel::Examine::Subs->new($p);

$des->run({pre_filter_dump => 1});

#print Dumper $cref;
