#!perl 
use warnings;
use strict;

use Test::More tests => 4;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{
    my $des = Devel::Examine::Subs->new(file => 't/sample.data');

    $des->_file({file => 'Pod::Usage'});

    use Data::Dumper;

    ok (! exists $INC{'Pod::Usage'}, "module unloaded if not previously loaded in _file()");
    ok (! $Pod::Usage::VERSION, "_file() also unloads an unloaded module");
}
{
    my $des = Devel::Examine::Subs->new;

    my $file = '/c:';

    eval { $des->_read_file({ file => $file }); };
    like ($@, qr/DES::_read_file\(\) can't create backup/, "_read_file() croaks if it can't create backup file");
}
