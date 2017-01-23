use warnings;
use strict;

use Test::More tests => 5;
use Test::More;
use File::Copy qw(copy);


BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'File::Edit::Portable' ) || print "Bail out!\n";
}

my $file = 'heredoc_bug/heredoc.pm';
my $copy = 'heredoc_bug/heredoc.copy';

my $des = Devel::Examine::Subs->new(
	file => $file,
	copy => $copy,
);

my $rw = File::Edit::Portable->new;

$des->inject(
	inject_after_sub_def => ['test()'],
);


my @c = $rw->read($copy);

is_deeply([@c[4,5,6,7]], [qw(one two three DOC)], 'heredoc left intact');

is ($c[10], "    test()", 'injects test() properly after sub def');

is ($c[17], "    test()", 'injects test() properly after sub def');
