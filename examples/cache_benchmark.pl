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

timethese(100, {
            'enabled' => 'cache_enabled',
            'disabled' => 'cache_disabled',
        });

sub cache_disabled {
    $des->all({cache => 0,}) for (1..10);
}
sub cache_enabled {
    $des->all({cache => 1,}) for (1..10);
}

__END__
Benchmark: timing 100 iterations of disabled, enabled...
  disabled: 72 wallclock secs (66.33 usr +  5.18 sys = 71.51 CPU) @  1.40/s (n=100)
   enabled:  0 wallclock secs ( 0.06 usr +  0.01 sys =  0.07 CPU) @ 1428.57/s (n=100)
