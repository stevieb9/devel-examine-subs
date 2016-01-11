#!perl 
use warnings;
use strict;

use Test::More tests => 3;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new(file => 't/sample.data');

$des->_file({file => 'Pod::Usage'});

use Data::Dumper;

ok (! exists $INC{'Pod::Usage'}, "module unloaded if not previously loaded in _file()");
ok (! $Pod::Usage::VERSION, "_file() also unloads an unloaded module");
