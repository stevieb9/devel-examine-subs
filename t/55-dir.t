#!perl 
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 4;

use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";

{
    my $des = Devel::Examine::Subs->new(file => 't');
    my $files = $des->all;  
    is (keys %$files, 5, "dir finds correct files");
}
{
    my $des = Devel::Examine::Subs->new(file => 't', extensions => ['*.t']);
    my $files = $des->all;  
    is (keys %$files, 52, "dir finds correct files with extensions param");
}
{
    my $des = Devel::Examine::Subs->new(file => 't');
    eval { $des->_write_file; };
    like ($@, qr/File::Edit::Portable/, "write_file can be called without a copy param");
}
