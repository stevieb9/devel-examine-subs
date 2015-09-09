#!/usr/bin/perl
use warnings;
use strict;

use feature 'say';

use Benchmark qw(timethese);

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;

my $file = 't/sample.data';
my $orig = 't/sample.data.orig';

my %params = (
                file => 't/test',
                search => 'this',
                pre_filter => 'subs',
                engine => 'objects',
#                pre_filter_return => 1,
              );

my $des = Devel::Examine::Subs->new(%params);

my $files = $des->objects();

for my $file (keys %$files){
    for my $sub (@{$files->{$file}}){

        say "Name: "        . $sub->name;
        say "First line: "  . $sub->start;
        say "Last line: "   . $sub->end;
        say "Num lines: "   . $sub->line_count;

        my $code = $sub->code;

        say "Sub code:";
        
        say "\t$_" for @$code;

        my $lines_with_search_term = $sub->lines;

        for (@$lines_with_search_term){
            my ($line_num, $text) = split /:/;
            say "Line num: $line_num";
            say "Code: $text\n";
        }

        print "\n\n";
    }
}
