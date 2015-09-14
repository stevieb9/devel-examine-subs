#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;

my $file = 't/sample.data';
my $copy = 't/test.data';

my %params = (
                file => $file,
                copy => $copy,
                search => 'this',
                code => ['# comment line one', '# comment line 2' ],
              );

my $des = Devel::Examine::Subs->new(%params);

my $struct = $des->inject_after(%params);

