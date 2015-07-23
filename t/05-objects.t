#!perl 
use warnings;
use strict;

use Test::More tests => 30;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $file = 't/sample.data';

my $p = {
    file => $file, 
    pre_filter => 'subs',
    engine => 'objects',
};

my $des = Devel::Examine::Subs->new($p);

my $objects = $des->run();

for my $o (@$objects){
    if ($o->name() eq 'eight'){
        is ($o->start(), 48, "sub eight starts at the right line");
        is ($o->end(), 50, "sub eight ends at the right line");
        is ($o->line_count(), 3, "sub eight has 3 lines, including def and }");
    } 
    if ($o->name() eq 'two'){
        is ($o->start(), 16, "sub two starts at the right line");
        is ($o->end(), 20, "sub two starts at the right line");
        is ($o->line_count(), 5, "sub two has 5 lines, including def and }");
    } 
}

eval { $objects = $des->objects(); };
ok (! $@, "objects() is callable and works" );

for my $o (@$objects){
    if ($o->name() eq 'four'){
        is ($o->start(), 29, "sub four starts at the right line");
        is ($o->end(), 34, "sub four ends at the right line");
        is ($o->line_count(), 6, "sub four has six lines, including the def and closing brace" );
    } 
    if ($o->name() eq 'six'){
        is ($o->start(), 42, "sub six starts at the right line");
        is ($o->end(), 44, "sub six starts at the right line");
        is ($o->line_count(), 3, "sub six has 4 lines, including the def and closing brace" );
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
