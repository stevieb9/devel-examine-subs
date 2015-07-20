#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;

my $file = 't/sample.data';
my $orig = 't/sample.data.orig';

my $params = {
                file => 't/sample.data',
                copy => 't/blah.data',
                pre_filter => 'subs && objects',
                engine => 'search_replace',
                engine_dump => 1,
                search => 'this',
                replace => 'that',
              };

my $des = Devel::Examine::Subs->new($params);

my $struct = $des->run($params);

copy $orig, $file;
