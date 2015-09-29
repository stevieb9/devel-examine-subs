#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;

my $ver = $ARGV[0] || die "\nsupply a version string\n";

my $des = Devel::Examine::Subs->new(
                            file => 'lib/Devel/Examine',
                            extensions => [qw(pm)],
                        );

my $cref = sub { 
        # this is the v5.12 way
        #$_[0] =~ s/^(package\s+\w+(?:::\w+)*)\s+\d+\.\d{2}/$1 $ver/; 
        $_[0] =~ s/^(our\s+\$VERSION\s+=\s+')/$1 $ver\';/; 
        
    };

my $ret = $des->replace(exec => $cref, limit => 1);
print Dumper $ret;
