#!perl -T
use warnings;
use strict;

use Test::More tests => 6;
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

my @files_to_delete = qw(
                    sample.data.bak
                    sample.data.orig
                    search_replace.data
                    search.replace.data.bak
                );

for (@files_to_delete){
    eval { unlink $_ if -f $_; };
    ok (! $@, "test file >>$_<< deleted ok" );
}

