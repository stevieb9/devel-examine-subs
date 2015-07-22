#!perl
#use warnings;
#use strict;

use Test::More tests => 6;
use Data::Dumper;

BEGIN {#1-2
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Prefilter' ) || print "Bail out!\n";
}

my $file = 't/sample.data';

# prefilter config

my $namespace = "Devel::Examine::Subs";
my $prefilter_module = $namespace . "::Prefilter";
my $compiler = $prefilter_module->new();
my $pre_filter = $compiler->{pre_filters}{subs}->();

{#3
    my $des = Devel::Examine::Subs->new({pre_filter => '', file => $file,});
    my $res = $des->run();
    
    ok ( ref($res) eq 'HASH', "no prefilter, data is sent through untouched" );
    for my $f (keys %$res){
        for my $s (keys $res->{$f}{subs}){
            ok ( ref($res->{$f}{subs}{$s}) eq 'HASH', "\$s->{file}{subs}{sub}: no prefilter, data is sent through untouched" );

        }
    }
}
{#4
    my $des = Devel::Examine::Subs->new({file => $file});

    my $cref = sub {
                my $p = shift;
                my $s = shift; 
                return (keys %$s)[0]; 
            };

    my $res = $des->run({pre_filter => $cref});

    is ($res, 't/sample.data', "single custom cref to pre_filter does the right thing" );

}
{#5
    my $des = Devel::Examine::Subs->new({file => $file});

    my $cref = sub {
                my $p = shift;
                my $s = shift; 
                return $s->{'t/sample.data'}{subs}; 
            };

    my $cref2 = sub {
                my $p = shift;
                my $s = shift;
                return $s->{four};
            };

    my $res = $des->run({pre_filter => [$cref, $cref2]});

    ok (ref $res eq 'HASH', "sending in an aref with two crefs to pre_filter returns the expected data" );
    is ($res->{end}, 33, "aref of crefs: good data");
    is ($res->{start}, 28, "aref of crefs: good data");
    is ($res->{num_lines}, 6, "aref of crefs: good data");
    ok (ref $res->{TIE_file_sub} eq 'ARRAY', "aref of crefs: good data");
    is ($res->{TIE_file_sub}[0], 'sub four {', "aref of crefs: good data");
}

{#6
    my $des = Devel::Examine::Subs->new();

    eval {
        $des->run({pre_filter => 'asdfasdf'});
    };

    ok ( $@, "pre_filter module croaks if an invalid internal prefilter name is passed in" );

}
{#7
    my $des = Devel::Examine::Subs->new();

    eval {
        $des->run({pre_filter => '_test && asdfasdf'});
    };

    print $@;
    ok ( $@, "pre_filter module croaks if an invalid internal prefilter name is passed in" );

}



{#7
    my $des = Devel::Examine::Subs->new();

    my $pf = $des->_pre_filter({pre_filter => 'subs'});

    eval {
        my $res = $pf->({}, [qw(a b c)]);
    };
 
    like ($@, qr/HASH/, "prefilter with 'sub' and an array, breaks internally");
   

}

sub _des {  
    my $p = shift; 
    my $des =  Devel::Examine::Subs->new({pre_filter => $p->{pre_filter}}); 
    return $des;
};
