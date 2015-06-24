#!perl -T

use Test::More tests => 9;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{#2
    my $res = Devel::Examine::Subs->line_numbers({ file => 't/sample.data'});
    ok ( ref($res) == 'HASH', "list_numbers() returns an href" );
}
{#3
    my $res = Devel::Examine::Subs->line_numbers({ file => 't/sample.data'});
    ok ( $res->{'one'}{'start'}, "line_numbers() contains 'start' subkey" );
}
{#4
    my $res = Devel::Examine::Subs->line_numbers({ file => 't/sample.data'});
    ok ( $res->{'one'}{'stop'}, "line_numbers() contains 'stop' subkey" );
}
{#5
    my $res = Devel::Examine::Subs->line_numbers({ file => 't/sample.data', search => 'asdfasdf' });
    ok ( $res->{one}{'start'}, "line_numbers() works as expected if search param is passed in" );
}
{#6
    my $res = Devel::Examine::Subs->line_numbers({ file => 't/sample.data' });
    ok ( ! $res->{'five '}, "line_numbers() can't catch a sub not on column one of file" );
}
{#7
    my $res = Devel::Examine::Subs->line_numbers({ file => 't/sample.data'});
    ok ( $res->{'six'}, "line_numbers() can get a sub if the above sub isn't at col 1" );
}
{#8
    my $res = Devel::Examine::Subs->line_numbers({ file => 't/sample.data' });
    is ( $res->{'eight'}{'start'}, 41, "line_numbers() catches properly when previous sub end isn't col 1" );
}
{#9
    my $res = Devel::Examine::Subs->line_numbers({ file => 't/sample.data' });
    is ( $res->{'eight'}{'stop'}, 43, "line_numbers() catches properly when previous sub end isn't col 1" );
}
{#10
    my $des = Devel::Examine::Subs->new();
    my $res = $des->line_numbers({ file => 't/sample.data', get => 'object' });
    is ( ref($res), 'ARRAY', "line_numbers() returns an aref when called with 'get' param" );
}
{#10
    my $res = Devel::Examine::Subs->line_numbers({ file => 't/sample.data' });
    is ( $res->{'eight'}{'stop'}, 43, "line_numbers() catches properly when previous sub end isn't col 1" );
}
{#12
    my $res = Devel::Examine::Subs->line_numbers({ file => 't/sample.data' });
    is ( $res->{'eight'}{'stop'}, 43, "line_numbers() catches properly when previous sub end isn't col 1" );
}

my $des = Devel::Examine::Subs->new();
