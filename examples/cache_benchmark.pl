#!/usr/bin/perl
use warnings;
use strict;

use Benchmark qw(timethese);

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;

my $file = 't/sample.data';
my $orig = 't/sample.data.orig';

my $params = {
                file => 'lib',
              };

my $des = Devel::Examine::Subs->new($params);

timethese(10, {
            'enabled' => 'cache_enabled',
            'disabled' => 'cache_disabled',
        });
sub cache_disabled {
    $des->all({cache => 0,}) for (1..10);
}
sub cache_enabled {
    $des->all({cache => 1,}) for (1..10);
}
