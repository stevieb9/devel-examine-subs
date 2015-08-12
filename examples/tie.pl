#!/usr/bin/perl
use warnings;
use strict;

use File::Copy;
use Tie::File;

my $f = 't/sample.data';
my $wf = 't/write_sample.data';

copy($f, $wf);

tie my @wfh, 'Tie::File', $wf;

for (@wfh){
    if (/sub seven/){
        $_ =~ s/seven/xxxxx/;
    }
}

untie @wfh;

open my $wfh, '<', $wf
  or die "Can't open test written file $wf: $!";

open my $fh, '<', $f
  or die "Can't open original test file $f: $!";

my @wf = <$wfh>;
my @f = <$fh>;

my $count = scalar @f;
my @changes;

for (0..$count){
    if ($wf[$_] and $wf[$_] ne $f[$_]){
        push @changes, $wf[$_];
    }
}
eval { close $fh; };
ok (! $@, "no problem closing the original test read file" );

eval { close $wfh; };
ok (! $@, "no problem closing the test write file" );

eval { unlink $wfh };
ok (! $@, "no problem deleting the test write file" );

is (@changes, 1, "search_replace on one line replaces only one line" );
