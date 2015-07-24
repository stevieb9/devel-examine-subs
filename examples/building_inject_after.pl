#!/usr/bin/perl
use warnings;
use strict;

use File::Copy;
use Tie::File;

my $f = 't/sample.data';
my $w = 't/test.data';

copy $f, $w;

my $file = $w;


my @things = qw(one two three);


tie my @a, 'Tie::File', $file;

my $line_num = 0;
my @code = ("# test comment line one", "# comment line 2");

my $dont_search = 0;

for (@a){
    $line_num++;
    if ($_ =~ /this/ && ! $dont_search){
        my $loc = $line_num;
        my $indent;
        if ($_ =~ /^(\s+)/ && $1){
            $indent = $1;
        }
        for my $line (@code){
            splice @a, $loc++, 0, $indent . $line;
            $dont_search++;
        }
        splice @a, $loc++, 0, '';
    }
    $dont_search-- if $dont_search != 0;
  
    print "$dont_search >> $line_num\n";
}

print "$_\n" for @a;
untie @a;

