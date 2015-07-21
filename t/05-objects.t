#!perl 
use warnings;
use strict;

use Test::More tests => 18;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $file = 't/sample.data';

my $p = {
    file => $file, 
    pre_filter => 'subs && objects',
    #pre_filter_dump => 1,
    pre_filter_return => 1,
};

my $des = Devel::Examine::Subs->new($p);

my $objects = $des->run();

for my $o (@$objects){
    if ($o->name() eq 'eight'){
        is ($o->start(), 48, "sub eight starts at the right line");
        is ($o->end(), 50, "sub eight ends at the right line");
    } 
    if ($o->name() eq 'two'){
        is ($o->start(), 16, "sub two starts at the right line");
        is ($o->end(), 20, "sub two starts at the right line");
    } 
}

eval { $objects = $des->objects(); };
ok (! $@, "objects() is callable and works" );

for my $o (@$objects){
    if ($o->name() eq 'four'){
        is ($o->start(), 29, "sub four starts at the right line");
        is ($o->end(), 34, "sub four ends at the right line");
    } 
    if ($o->name() eq 'six'){
        is ($o->start(), 42, "sub six starts at the right line");
        is ($o->end(), 44, "sub six starts at the right line");
    } 
}

{
    my $params = {file => 't/test'};
    my $des = Devel::Examine::Subs->new($params);
    my $struct = $des->objects();

    for my $file (keys %$struct){
        for my $o (@$objects){
           if ($o->name() eq 'four'){
               is ($o->start(), 29, "sub four starts at the right line in dir");
               is ($o->end(), 34, "sub four ends at the right line in dir");
           } 
           if ($o->name() eq 'six'){
               is ($o->start(), 42, "sub six starts at the right line in dir");
               is ($o->end(), 44, "sub six starts at the right line in dir");
           } 
           if ($o->name() eq 'eight'){
               is ($o->start(), 48, "sub eight starts at the right line in dir");
               is ($o->end(), 50, "sub eight ends at the right line in dir");
           } 
           if ($o->name() eq 'two'){
               is ($o->start(), 16, "sub two starts at the right line in dir");
               is ($o->end(), 20, "sub two starts at the right line in dir");
           } 
       }
    }
}
#print Dumper $des->objects();
