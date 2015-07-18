#!perl -T

use Test::More tests => 2;
use File::Copy qw(copy);

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

unlink 't/write_sample.data';

eval { 
    open my $copy_fh, '<', 't/write_sample.data'
      or die "Can't open the write test copied file: $!";
};

like ( $@, qr/open the write/, "Test sample.data unlinked/deleted successfully" );
