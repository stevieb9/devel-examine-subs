#!perl 
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 24;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{#valid params
    
    my $des = Devel::Examine::Subs->new();

    my %vp = $des->valid_params();

    is( keys %vp, 29, "valid_params() returns proper number of valid params");
    my @persistent;
    my @transient;

    for (keys %vp){
        push @persistent, $_ and next if $vp{$_};
        push @transient, $_;
    }

    is (@persistent, 10, "valid_params() returns the correct num of persistent params");
    is (@transient, 19, "valid_params() returns the correct num of transient params");

    my @valid = qw(
          no_indent
          diff
          file
          pre_proc
          regex
          copy
          engine
          pre_filter
          extensions
          cache_enabled
    );

    for (@valid){
        ok (grep(/^$_$/, @persistent), "$_ is correctly validated");
    }
    for (@persistent){
        ok (grep(/^$_$/, @valid), "$_ matches valid");
    }
}
