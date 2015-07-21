#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;

my $file = 't/sample.data';
my $orig = 't/sample.data.orig';

my $params = {
                file => $file,
                search => 'this',
                pre_filter => 'file_lines_contain',
#                pre_filter_dump => 2,
#                pre_filter_return => 1,
                engine => \&new_has,
#                core_dump => 1,
#                engine_dump => 1,
#                engine_dump => 1,
#                copy => 't/inject_after.data',
#                code => ['# comment line one', '# comment line 2' ],
              };


sub new_has {

    my $p = shift;
    my $struct = shift;

    print Dumper $struct;
    my @has;

    my $file = (keys %$struct)[0];

    @has = keys %{$struct->{$file}{subs}};

    return \@has;
}

my $des = Devel::Examine::Subs->new($params);
my $struct = $des->run($params);

print "$_\n" for @$struct;

#print Dumper $struct;
