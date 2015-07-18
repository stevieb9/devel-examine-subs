#!perl -T

use Test::More tests => 3;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

    my $des = Devel::Examine::Subs->new({file => 't/sample.data'});

{#2
    eval { $des->_config({file => 'asdfadf'}) };
    like ( $@, qr/Invalid file supplied/, "_config() dies with error if file not found" );
}
{#3
    $des->_config({
                file => 't/sample.data',
                search => 'this',
                lines => 1,
                get => 'obj',
                test => 1,
              });
    is ( keys %{$des->{params}}, 5, "_config() sets $self->{params}, and properly" );
}
