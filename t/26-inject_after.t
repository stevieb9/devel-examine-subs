#!perl -T
use warnings;
use strict;

use Test::More tests => 141;
use Tie::File;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{#1
    my $base_file = 't/orig/inject_after.data';

    my $params = {
                    file => 't/sample.data',
                    copy => 't/inject_after.data',
                    pre_filter => 'file_lines_contain && subs && objects',
                    engine => 'inject_after',
                    search => 'this',
                    code => ['# comment line one', '# comment line 2' ],
                  };

    my $des = Devel::Examine::Subs->new($params);

    my $struct = $des->run();

    ok ( ref($struct) eq 'ARRAY', "search_replace engine returns an aref" );
    ok ( $struct->[0] =~ qr/\w+/, "elems of inject_after are simple names of subs" );
    is ( @$struct, 5, "return from inject_after contains the proper number of subs with 'file_lines_contain' prefilter" );

    my (@base_file, @test_file);

    eval { tie @base_file, 'Tie::File', $base_file or die $!; };
    ok (! $@, "tied $base_file ok for inject_after" );

    eval { tie @test_file, 'Tie::File', $params->{copy} or die $!; };
    ok (! $@, "tied $params->{copy} ok for inject_after" );

    my $i = 0;
    for (@base_file){
        ok ($base_file[$i] eq $test_file[$i], "Line $i in base file matches line $i in test file" );
        $i++;
    }
}
{#2
    my $base_file = 't/orig/inject_after.data';

    my $params = {
                    file => 't/sample.data',
                    copy => 't/inject_after.data',
                    search => 'this',
                    code => ['# comment line one', '# comment line 2' ],
                  };

    my $des = Devel::Examine::Subs->new($params);

    my $struct = $des->inject_after();

    ok ( ref($struct) eq 'ARRAY', "inject_after() returns an aref" );
    ok ( $struct->[0] =~ qr/\w+/, "elems of inject_after() are simple names of subs" );
    is ( @$struct, 5, "return from inject_after() contains the proper number of subs with 'file_lines_contain' prefilter" );

    my (@base_file, @test_file);

    eval { tie @base_file, 'Tie::File', $base_file or die $!; };
    ok (! $@, "tied $base_file ok for inject_after()" );

    eval { tie @test_file, 'Tie::File', $params->{copy} or die $!; };
    ok (! $@, "tied $params->{copy} ok for inject_after()" );

    my $i = 0;
    for (@base_file){
        ok ($base_file[$i] eq $test_file[$i], "Line $i in base file matches line $i in test file for inject_after()" );
        $i++;
    }
}
