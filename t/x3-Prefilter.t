#!perl -T

use Test::More tests => 7;

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
    my $pre_filter = $des->_pre_filter();
    ok ( ref($pre_filter) eq 'CODE', "a returned \$pre_filter is a CODE ref" );
}
{#3 #FIXME: check for obj type (class)
    my $pre_filter_return = Devel::Examine::Subs::Prefilter->object();
    is ( ref($pre_filter_return), 'HASH', "pre_filter returns a hashref" );
}
{#4
    my $h = {a => 1};
    my $des = Devel::Examine::Subs->new();
    my $pre_filter = $des->_pre_filter();
    my $res = $pre_filter->($h);
    
    print Dumper $res;
   
    is_deeply ($h, $res, "when no prefilter is passed in, the default returns the original obj" ); 
}

sub _des {  
    my $p = shift; 
    my $des =  Devel::Examine::Subs->new({pre_filter => $p->{pre_filter}}); 
    return $des;
};
