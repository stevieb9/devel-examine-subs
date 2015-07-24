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
Benchmark: timing 10 iterations of disabled, enabled...
  disabled: 76 wallclock secs (66.49 usr +  5.31 sys = 71.80 CPU) @  0.14/s (n=10)
   enabled:  0 wallclock secs ( 0.07 usr +  0.01 sys =  0.08 CPU) @ 125.00/s (n=10)

