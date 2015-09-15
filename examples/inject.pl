#!/usr/bin/perl
use strict;
use warnings;

use Devel::Examine::Subs;

my $des = Devel::Examine::Subs->new( file => '/home/steve02/devel/repos/test-subs/lib/Devel/Examine');

my $statements = ['use Devel::Trace::Flow qw(trace trace_dump);'];

$des->inject(inject_use => $statements);
