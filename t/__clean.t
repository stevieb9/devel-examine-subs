#!perl
use warnings;
use strict;

use Test::More tests => 20;
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
                    t/replace_copy.data
                    t/sample.data.bak
                    t/sample.data.orig
                    t/search_replace.data
                    t/search_replace_cref.data
                    t/search.replace.data.bak
                    t/inject_after.data
                    t/test.bak
                    t/test.data
                );
my @bak_glob = <*.bak>;

push @files_to_delete, @bak_glob;

for (@files_to_delete){
    eval { unlink $_ if -f $_; };
    ok (! $@, "test file >>$_<< deleted ok" );
}

exit if $@;
