#!perl
use warnings;
use strict;

use Test::More tests => 5;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new({file => 't/sample.data'});

{#2
     my $res = $des->has({ search => 'thi?s' });
         ok ( ! @$res, "search doesn't act as a regex when unescaped" );
}
{#3
     my $res = $des->has({ search => 'thi\?s' });
     ok ( ! @$res, "search char escaping works" );
}
{#4
     my $res = $des->has({ regex => 1, search => 'thi?s' });
     ok ( @$res, "if regex is set, search becomes a regex" );
}
{#5
     my $res = $des->has({ regex => 1, search => 'th*i?s' });
     ok ( @$res, "if regex is set, search becomes a regex" );
}




