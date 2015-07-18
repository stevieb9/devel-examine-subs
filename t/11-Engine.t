#!perl -T

use Test::More tests => 7;

BEGIN {#1-2
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Engine' ) || print "Bail out!\n";
}

# engine config
my $namespace = "Devel::Examine::Subs";
my $engine_module = $namespace . "::Engine";
my $compiler = $engine_module->new();
my $engine = \&{$compler->{engines}{_test}};

{#3
    ok ( ref($engine) eq 'CODE', "a returned \$engine is a CODE ref" );
}
{#4
    my $engine_return = Devel::Examine::Subs::Engine->_test();
    is ( ref($engine_return), 'HASH', "_test engine returns a hashref" );
}
{#5
    $engine = _engine('_test');
    my $res = $engine->();

    is ( ref($res), 'HASH', "_test engine returns a hashref properly" );
}
{#6
    my $des = _des({engine => '_test'});
    my $engine = $des->_engine();
    is ( ref($engine), 'CODE', "_load_engine() returns a cref properly" );
    print Dumper $engine;
    is ( ref($engine->()), 'HASH', "the _test engine returns a hashref" );
}
sub _engine { 
    my $p = shift; 
    return \&{$compiler->{engines}{$p}}; 
};

sub _des {  
    my $p = shift; 
    my $des =  Devel::Examine::Subs->new({engine => $p->{engine}}); 
    return $des;
};
