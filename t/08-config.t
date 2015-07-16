#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

    my $des = Devel::Examine::Subs->new({file => 't/sample.data'});

{
    eval { $des->_config({file => 'asdfadf'}) };
    like ( $@, qr/Invalid file supplied/, "_config() dies with error if file not found" );
}
{
    $des->_config({
                file => 't/sample.data',
                search => 'this',
                lines => 1,
                get => 'obj',
                test => 1,
              });
    is ( keys %$des, 6, "_config() only sets allowed params" );
}
