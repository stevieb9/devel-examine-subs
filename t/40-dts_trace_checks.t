#!perl 
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 12;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

eval {
    require Devel::Trace::Subs;
    import Devel::Trace::Subs qw(trace trace_dump);
};

SKIP: {

    skip "Devel::Trace::Subs not installed... skipping", 11 if $@;

    $ENV{DES_TRACE} = 1;

    my $des = Devel::Examine::Subs->new(file => 't/sample.data');

    my $trace = trace();

    is (ref $trace, 'HASH', "stack trace is a hash ref");
    is (ref $trace->{flow}, 'ARRAY', "code flow is an array ref");
    is (ref $trace->{stack}, 'ARRAY', "stack is an array ref");

    is (scalar @{ $trace->{flow} }, 8, "code flow has the proper number of entries");
    is (scalar @{ $trace->{stack} }, 8, "stack has the proper number of entries");

    my @stack_items = keys %{ $trace->{stack}->[0] };

    is (@stack_items, 5, "stack trace entries have the proper number of headings");

    my %entries = map {$_ => 1} qw(in filename line package sub);
    
    for my $entry (@stack_items){
        ok ($entries{$entry}, "$entry is in stack trace headings");
    }
};
