#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;

my $file = 't/sample.data';
my $orig = 't/sample.data.orig';

my %params = (
                file => $file,
                search => 'this',
#                pre_proc => ,
#                pre_proc_return => 1,
#                pre_proc_dump => 1,
                post_proc => 'file_lines_contain',
#                post_proc_dump => 1,
#                post_proc_return => 1,
                engine => dumps(),
#                engine_return => 1,
#                engine_dump => 1,
#                core_dump => 1,
#                copy => 't/inject_after.data',
#                code => ['# comment line one', '# comment line 2' ],
              );

#<des>
sub dumps {

    return sub {

        my $p = shift;
        my $struct = shift;

        use Data::Dumper;
        print Dumper $struct;
    };
}
#</des>

my $des = Devel::Examine::Subs->new(%params);

#my $struct = $des->run(\%params);
#print Dumper $struct;

# uncomment below line to inject the code
# after you're certain the return is correct

$des->add_functionality(add_functionality => 'engine');

