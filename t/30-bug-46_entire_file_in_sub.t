#!perl
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 16;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new();

my $params = {
            file => 't/sample.data',
            pre_filter => 'subs',
        };

my $aref = $des->run($params);

ok (ref $aref eq 'ARRAY', "subs prefilter returns aref" );
ok (ref $aref->[0]{file} eq 'ARRAY', "'file' attr in sub framework is aref" );

for (@$aref){
    is (@{$_->{file}}, 50, "sub $_->{name}'s complete file array has correct number of lines" );
}

eval {
    for (@$aref){
        if (! ( @{$_->{file}} == 50 )){
            die "not all subs from 'subs' prefilter have the full perl file";
        }
    }
};

ok (! $@, "all subs returned from 'subs' prefilter have the full perl file" );    

eval {
    for (@$aref){
        if (! ( @{$_->{file}} == 9999 )){
            die "not all subs from 'subs' prefilter have the full perl file";
        }
    }
};

ok ($@, "we can catch if 'subs' prefilter return arefs have bad full file info" );    
