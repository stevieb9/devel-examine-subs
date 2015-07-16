#!perl -T

# for testing internal subs, either directly,
# or through an accessor

use Test::More tests => 5;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}
{
    my $des = Devel::Examine::Subs->new();
    eval { $des->has({ file => 'badfile.none', search => 'text', }) };
    like ( $@, qr/Invalid file supplied/, "has() dies with error if file not found" );
}
{#2
    my $des = Devel::Examine::Subs->new();
    is ( ref $des, 'Devel::Examine::Subs', "new() instantiates a new blessed object" );
}
{#3
    my $des = _des({engine => '_test'});
    my $engine = $des->_load_engine();
    is ( ref($engine), 'CODE', "new() will return an engine with {engine=>'engine'} param" );
    is ( ref($engine->()), 'HASH', "new({engine => 'engine'}) does the right thing" );
}

sub _des {  
    my $p = shift; 
    my $des =  Devel::Examine::Subs->new($p); 
    return $des;
}

