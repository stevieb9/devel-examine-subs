#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use PPI;
use Tie::File;

my $file = '../devel-trace-flow/t/sample.pl';

my $PPI_doc = PPI::Document->new($file);
#my $PPI_subs = $PPI_doc->find("PPI::Statement::Sub");
my $incs = $PPI_doc->find("PPI::Statement::Include");

#print Dumper $incs;
#print Dumper $PPI_doc;

tie my @file, 'Tie::File', $file;

my $search = qr/use\s+\w+/;

my $index = grep {$file[$_] =~ $search } 0..$#file;

splice @file, $index + 1, 0, 'use Devel::Trace::Flow qw(trace trace_dump);';

print "$file[$_]\n" for (1..5);

print "** $index\n";
