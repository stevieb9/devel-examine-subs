#!perl 
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 9;
use Test::Trap;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new({
                            file => 't',
                            cache => 1,
                          });
{#3 cache file
    $des->run_directory();
    is($des->cache_status('files'), 0, "files cache not used on new call");
    $des->run_directory();
    is($des->cache_status('files'), 1, "files cache is used on subsequent call");
    $des->run_directory();
    is($des->cache_status('files'), 1, "files cache is used on further subsequent call");
    $des->run_directory({extensions => ['data']});
    is($des->cache_status('files'), 0, "files cache not used if extensions changed");
    $des->run_directory();
    is($des->cache_status('files'), 1, "files cache is used on subsequent call");
    $des->run_directory();
    is($des->cache_status('files'), 1, "files cache is used on subsequent call");
    $des->run_directory({file => 'lib'});
    is($des->cache_status('files'), 0, "files cache not used if 'file' changed");
    $des->run_directory();
    is($des->cache_status('files'), 1, "files cache is used on subsequent call");
    $des->run_directory();
    is($des->cache_status('files'), 1, "files cache is used on further subsequent call");
}
__END__
{#2 - cache

    my $file = 't/cache_dump.debug';

    # the first execution won't print a cache, as it
    # hasn't been created yet

    $des->run();

    do {
        
        eval { open STDOUT, '>', $file or die $!; };
        ok (! $@, "STDOUT redirected for cache dump");

        my @exit = trap { $des->all({cache_dump => 1}); };

        eval { print STDOUT $trap->stdout; };

        is (! $trap->stdout, '', "output to stdout" );
        ok (! $@, "cache dump gave no errors" );

    };

    eval { open my $fh, '<', $file or die $!; };
    ok (! $@, "cache dump output file exists and can be read" );
    open my $fh, '<', $file or die $!;

    my @cache_dump = <$fh>;
    ok ( ! grep {$_ =~ /VAR1 = undef/} @cache_dump, "cache isn't empty" );
    ok ( @cache_dump > 10, "cache dump contains legit data" );

    eval { close $fh; };
    ok (! $@, "cache dump output file closed successfully" );

    eval { unlink $file; };

    ok (! $@, "cache dump temp file deleted successfully" );
}

