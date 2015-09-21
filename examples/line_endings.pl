#!/usr/bin/perl

use warnings;
use strict;

my @data = <DATA>;

for (@data){
    s/\R//g;
    print "$_"
}

__DATA__
sub one {
    print "hello, world!\n";
    exit;
}
sub two {
    my $thing = "hi there\r\n";
}
