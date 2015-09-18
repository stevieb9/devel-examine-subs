#!/usr/bin/perl
use strict;
use warnings;

use Devel::Examine::Subs;

my $des = Devel::Examine::Subs->new( file => 't/sample.data');

my $statements = ['use WHATEVER::MODULE'];

$des->inject(inject_use => $statements);
