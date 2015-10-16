#!/usr/bin/perl
use warnings;
use strict;

use Devel::Examine::Subs::Engine;

my $cmd = '_test_print';
my $namespace = 'Devel::Examine::Subs';

# we got an engine name...

my $engine;

if (not ref($cmd) eq 'CODE'){

    my $engine_module = $namespace . "::Engine";
    my $compiler = $engine_module->new();

    $engine = \&{$compiler->{engines}{$cmd}};
}

$engine->();

