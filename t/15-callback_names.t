#!perl -T
use warnings;
use strict;

use Test::More tests => 22;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs::Engine' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Prefilter' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $pf = Devel::Examine::Subs::Prefilter->new();
my $e = Devel::Examine::Subs::Engine->new();
my $pf_dt = $pf->_dt();
my $e_dt = $e->_dt();

{
    my $des = Devel::Examine::Subs->new();
    my @pre_filters = $des->pre_filters();
    my @engines = $des->engines();
    
    isa_ok(\@pre_filters, 'ARRAY', "pre_filters() returns an array");
    isa_ok(\@engines, 'ARRAY', "engines() returns an array");

    for (keys %$pf_dt){
        ok ( grep /$_/, @pre_filters, "pre_filters() returns all the filter names" );
    }
    for (keys %$e_dt){
        ok ( grep /$_/, @engines, "pre_filters() returns all the filter names" );
    }


}
