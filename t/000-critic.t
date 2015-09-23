#!perl 
use warnings;
use strict;

use Test::More tests => 81;

{
    ## no critic

    eval " 
        use Test::Perl::Critic (-exclude => [
                            'ProhibitNoStrict',
                            'RequireBarewordIncludes',
                            'ProhibitNestedSubs',
                        ]);
    ";
};

plan skip_all => "Skipped! Test::Perl::Critic not installed" if $@;


all_critic_ok('.');

