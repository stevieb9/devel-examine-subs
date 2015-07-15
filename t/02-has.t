#!perl -T

use Test::More tests => 13;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new({file => 't/sample.data'});

{#2
    eval { my $des = Devel::Examine::Subs->has({ file => 'badfile.none'}) };
    ok ( $@ =~ /Invalid file supplied/, "new() dies with error if file not found" );
}
{#3
    my $des = Devel::Examine::Subs->new();
    my @res = $des->has({ file => 't/sample.data', search => 'this' });
    ok ( $res[0] =~ '\w+', "has() returns an array if file exists and text available" );
}
{#8
    my @res = $des->has({ file => 't/sample.data', search => 'this' });
    ok ( $res[0] =~ '\w+', "obj->has() returns an array if file exists and text available" );
}
{#9
    my @res = $des->has({ file => 't/sample.data', search => '' });
    ok ( ! @res, "obj->has() returns an empty array if file exists and text is empty string" );
}
{#10
    my @res = $des->has({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( ! @res, "obj->has() returns an empty array if file exists and search text not found" );
}
{#11    
    my $res = $des->has({ file => 't/sample.data', search => 'this' });
    ok ( ref \$res eq 'SCALAR', "obj->has() returns a scalar when called in scalar context" );
}
{#12
    my %res = $des->has({ file => 't/sample.data', search => 'this', lines => 1 });
    ok ( ref \%res eq 'HASH', "has() returns a hash when called with lines param" );
}
{#13-17
    my %res = $des->has({ file => 't/sample.data', search => 'this', lines => 1 });
    for my $key (keys %res){
        ok (ref($res{$key}) eq 'ARRAY', "has()  hash contains array refs for 'lines'" );
    }
}

