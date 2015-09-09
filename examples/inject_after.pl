#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;

my $file = 't/sample.data';
my $orig = 't/sample.data.orig';

my %params = (
                file => 't/sample.data',
                copy => 't/inject_after.data',
                #pre_filter => ['subs', 'objects'],
                pre_filter => ['file_lines_contain', 'subs', 'objects'],
                engine => 'inject_after',
                search => 'this',
                code => ['# comment line one', '# comment line 2' ],
              );

my $des = Devel::Examine::Subs->new(%params);

my $struct = $des->run(\%params);

print Dumper $struct;
