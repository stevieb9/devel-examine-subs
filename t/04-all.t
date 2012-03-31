#!perl -T

use Test::More tests => 12;
use Test::Exception;

BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{
    my @res = Devel::Examine::Subs->all({ file => 't/sample.data', search => 'aaa' });
    ok ( $res[0] =~ '\w+', "all() returns an array" );
}
{
    my @res = Devel::Examine::Subs->all({ file => 't/sample.data', search => '' });
    ok ( @res, "all() returns an array if file exists and text is empty string" );
}
{
    my @res = Devel::Examine::Subs->all({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( @res, "all() returns an array if file exists and search text not found" );
}
{
    my $res = Devel::Examine::Subs->all({ file => 't/sample.data' });
    ok ( ref \$res eq 'SCALAR', "all() returns a scalar when called in scalar context" );
}
{
    my $res = Devel::Examine::Subs->all({ file => 't/sample.data', search => 'this' });
    is ( $res, 5, "all() returns the proper count of names when data is found" );
}
{
    my $res = Devel::Examine::Subs->all({ file => 't/sample.data' });
    is ( $res, 5, "all() does the right thing with no text param" );
}

my $des = Devel::Examine::Subs->new();

{
    my @res = $des->all({ file => 't/sample.data', search => '' });
    ok ( @res, "obj->all() returns an array if file exists and text is empty string" );
}
{
    my @res = $des->all({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( @res, "obj->all() returns an array if file exists and search text not found" );
}
{
    my $res = $des->all({ file => 't/sample.data' });
    ok ( ref \$res eq 'SCALAR', "obj->all() returns a scalar when called in scalar context" );
}
{
    my $res = $des->all({ file => 't/sample.data', search => 'this' });
    is ( $res, 5, "obj->all() returns the proper count of names when data is found" );
}
{
    my $res = $des->all({ file => 't/sample.data' });
    is ( $res, 5, "obj->all() does the right thing with no text param" );
}

