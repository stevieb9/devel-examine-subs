#!perl
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 8;
use Test::Trap;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new(
                            file => 't/sample.data',
                          );
{#2 - pre_proc dump

    my $file = 't/pre_proc_dump.debug';

    do {
        
        eval { open STDOUT, '>', $file or die $!; };
        ok (! $@, "STDOUT redirected for pre_proc dump");

        my @exit = trap { $des->module(module => 'Data::Dumper', pre_proc_dump => 1); };

        eval { print STDOUT $trap->stdout; };
        is (! $trap->stdout, '', "output to stdout" );
        ok (! $@, "pre_proc dump gave no errors" );

    };

    eval { open my $fh, '<', $file or die $!; };
    ok (! $@, "pre_proc dump output file exists and can be read" );
    open my $fh, '<', $file or die $!;
    
    my @lines = <$fh>;
    is (@lines, 45, "Based on test data, pre_proc dump dumps the correct info" );

    eval { close $fh; };
    ok (! $@, "pre_proc dump output file closed successfully" );

    eval { unlink $file; };
    ok (! $@, "pre_proc dump temp file deleted successfully" );
}
