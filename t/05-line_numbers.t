#!perl -T

use Test::More tests => 8;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{#2
    my $des = Devel::Examine::Subs->new();
    my $res = $des->line_numbers({ file => 't/sample.data', get => 'object' });
    is ( ref($res), 'ARRAY', "line_numbers() returns an aref when called with 'get' param" );
}
{#3
    my $des = Devel::Examine::Subs->new();
    my $res = $des->line_numbers({ file => 't/sample.data', get => 'obj' });
    is ( ref($res), 'ARRAY', "line_numbers() does the right thing when 'get' param is set to 'obj'" );
}
{#4
    my $des = Devel::Examine::Subs->new();
    my $res = $des->line_numbers({ file => 't/sample.data', get => 'object' });
    is ( ref($res->[0]), 
            'Devel::Examine::Subs::Sub', 
            "The elements in the aref returned by line_numbers() are proper objects" 
    );
}
{#5-9
    my $des = Devel::Examine::Subs->new();
    my $res = $des->line_numbers({ file => 't/sample.data', get => 'object' });
    for (qw(name start stop count)){
        can_ok( $res->[0], $_ );
    }
}

my $des = Devel::Examine::Subs->new();
