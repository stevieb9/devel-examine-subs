#!perl -T

use Test::More tests => 3;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

    my $des = Devel::Examine::Subs->new({file => 't/sample.data', search => 'this', engine => '_test'});

{#2
    $des->_config({engine => '_test_print'});
    ok ( $des->{params}{engine} eq '_test_print', "_config() properly sets $self->{params}" );

}
{#3
    $des->_config({
                file => 't/sample.data',
                search => 'this',
                lines => 1,
                get => 'obj',
                test => 1,
              });
    is ( keys %{$des->{params}}, 7, "_config() sets $self->{params}, and properly" );
}
