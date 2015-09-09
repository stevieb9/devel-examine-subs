#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;

my $file = 't/sample.data';
my $orig = 't/sample.data.orig';

my $params = {
            add_functionality => 'engine',      
        };

#<des>
sub testing {

    return sub {

        my $p = shift;
        my $struct = shift;

        my $file = (keys %$struct)[0];

        my @has = keys %{$struct->{$file}{subs}};

        return \@has;
    };
}
#</des>

my $des = Devel::Examine::Subs->new($params);
$des->add_functionality($params);
