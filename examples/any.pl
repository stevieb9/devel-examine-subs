#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;

my $file = 't/sample.data';
my $orig = 't/sample.data.orig';

my %params = (
                file => '.',
                #copy => 't/inject_after.data',
                #pre_filter => 'subs && objects',
                engine => 'all',
                #search => 'this',
                #code => ['# comment line one', '# comment line 2' ],
              );

my $des = Devel::Examine::Subs->new(%params);

my $struct = $des->run(\%params);

