#!perl -T

use Test::More tests => 7;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Prefilter' ) || print "Bail out!\n";
}

# prefilter config
my $namespace = "Devel::Examine::Subs";
my $prefilter_module = $namespace . "::Prefilter";
my $compiler = $prefilter_module->new();

{#2
    my $des = Devel::Examine::Subs->new();
    my $res = $des->_pre_filter([qw(a b c)]);
    ok ( ref($res) eq 'ARRAY', "no params to pre_filter, what went in came out" );
}
{#3 #FIXME: check for obj type (class)
    my $pre_filter_return = Devel::Examine::Subs::Prefilter->object();

    #is ( ref($pre_filter_return), 'HASH', "pre_filter returns a hashref" );
}
{#4
    my $h = {a => 1};
    my $des = Devel::Examine::Subs->new();
   
    my $res = $des->_pre_filter($h); 
    is_deeply ($h, $res, "when no prefilter is passed in, the default returns the original obj" )
}
__END__ #FIXME! 'object' pre_filter doesn't work
{#5

    my $des = Devel::Examine::Subs->new({pre_filter => 'object', file => 't/sample.data'});
    my $subs = $des->_load_subs();
    $subs = $des->_pre_filter($subs);
    print Dumper $subs;
}
sub _des {  
    my $p = shift; 
    my $des =  Devel::Examine::Subs->new({pre_filter => $p->{pre_filter}}); 
    return $des;
};
