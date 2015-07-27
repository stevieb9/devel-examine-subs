#!perl 
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 6;
use Test::Trap;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new({
                            file => 't/sample.data',
                            cache => 0,
                            include => [],
                            exclude => [],
                            hello => 'world',
                            goodbye => 'world',
                          });


$des->_config_clean();

is (keys %{$des->{params}}, 4, "after _config_clean(), persistent params remain");

my @persistent = qw(cache file include exclude);

for my $p (keys %{$des->{params}}){
    ok ((grep {$p eq $_} @persistent), "$p is a valid persistent param");
}
