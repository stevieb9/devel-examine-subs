#!perl -T
use warnings;
use strict;

use Test::More tests => 8;
use Test::Trap;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new({
                            file => 't/sample.data',
                            engine => 'all',
                            pre_filter => 'subs',
                          });
{#2 - pre_filter dump

    my $file = 't/pre_filter_dump.debug';

    do {
        
        eval { open STDOUT, '>', $file or die $!; };
        ok (! $@, "STDOUT redirected for pre_filter dump");

        my @exit = trap { $des->run({pre_filter_dump => 1}); };

        eval { print STDOUT $trap->stdout; };
        is (! $trap->stdout, '', "output to stdout" );
        ok (! $@, "pre_filter dump gave no errors" );

    };

    eval { open my $fh, '<', $file or die $!; };
    ok (! $@, "pre_filter dump output file exists and can be read" );
    open my $fh, '<', $file or die $!;
    
    my @lines = <$fh>;
    is (@lines, 706, "Based on test data, pre_filter dump dumps the correct info" );

    eval { close $fh; };
    ok (! $@, "pre_filter dump output file closed successfully" );

    eval { unlink $file; };
    ok (! $@, "pre_filter dump temp file deleted successfully" );
}
