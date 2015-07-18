#!perl -T
#use warnings;
#use strict;

use Test::More tests => 6;
use Data::Dumper;

BEGIN {#1-2
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Prefilter' ) || print "Bail out!\n";
}

# prefilter config
my $namespace = "Devel::Examine::Subs";
my $prefilter_module = $namespace . "::Prefilter";
my $compiler = $prefilter_module->new();
my $pre_filter = $compiler->{pre_filters}{subs}->();

{#3
    my $des = Devel::Examine::Subs->new();
    my $res = $des->_pre_filter({},[qw(a b c)]);
    ok ( ref($res) eq 'ARRAY', "no params to pre_filter, what went in came out" );
}
{#4
    my $h = {a => 1};
    my $des = Devel::Examine::Subs->new();
    my $res = $des->_pre_filter({},$h); 
    is_deeply ($h, $res, "when no prefilter is passed in, the default returns the original obj" )
}
{#5
    my $des = Devel::Examine::Subs->new();

    my $cref = sub {
                my $p = shift;
                my $s = shift; 
                $s->[1]=55; 
                return $s;
            };

    my $pf = $des->_pre_filter({pre_filter => $cref});

    my $res = $pf->({}, [qw(a b c)]);

}
{#6
    my $des = Devel::Examine::Subs->new();

    my $cref = sub {
                my $p = shift;
                my $s = shift; 
                $s->[1]=55; 
                return $s;
   };

    my $pf = $des->_pre_filter({pre_filter => $cref});

    my $res = $pf->({}, [qw(a b c)]);
    
    ok ( ref($res) eq 'ARRAY', "prefilter with ref of sub" );

}
{#7
    my $des = Devel::Examine::Subs->new();

    my $pf = $des->_pre_filter({pre_filter => 'subs'});

    eval {
        my $res = $pf->({}, [qw(a b c)]);
    };
 
    like ($@, qr/HASH/, "prefilter with 'sub' and an array, breaks internally");
   

}

sub _des {  
    my $p = shift; 
    my $des =  Devel::Examine::Subs->new({pre_filter => $p->{pre_filter}}); 
    return $des;
};
