#!perl -T

use Test::More tests => 14;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new({file => 't/sample.data'});

{#2
    my $des2 = Devel::Examine::Subs->new();
    eval { $des2->has({ file => 'badfile.none'}) };
    ok ( $@ =~ /Invalid file supplied/, "new() dies with error if file not found" );
}
{#3
    my $des = Devel::Examine::Subs->new();
    my @res = $des->has({ file => 't/sample.data', search => 't?h$is' });
    ok ( $res[0] =~ '\w+', "has() returns an array if file exists and text available" );
}
{#4
    my @res = $des->has({ file => 't/sample.data', search => 'this' });
    ok ( $res[0] =~ '\w+', "obj->has() returns an array if file exists and text available" );
}
{#5
    my @res = $des->has({ file => 't/sample.data', search => '' });
    ok ( ! @res, "obj->has() returns an empty array if file exists and text is empty string" );
}
{#6
    my @res = $des->has({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( ! @res, "obj->has() returns an empty array if file exists and search text not found" );
}
{#7    
    my $res = $des->has({ file => 't/sample.data', search => 'this' });
    ok ( ref \$res eq 'SCALAR', "obj->has() returns a scalar when called in scalar context" );
}
{#8
    my %res = $des->has({ file => 't/sample.data', search => 'this', lines => 1 });
    ok ( ref \%res eq 'HASH', "has() returns a hash when called with lines param" );
}
{#9-13
    my %res = $des->has({ file => 't/sample.data', search => 'this', lines => 1 });
    for my $key (keys %res){
        ok (ref($res{$key}) eq 'ARRAY', "has()  hash contains array refs for 'lines'" );
    }
}
{#14
    my $des = Devel::Examine::Subs->new({file => 't/sample.data'});
    my @res = $des->has({ search => 'this' });
    ok ( $res[0] =~ '\w+', "has() returns an array if new() takes 'file' and has() doesn't" );
}

