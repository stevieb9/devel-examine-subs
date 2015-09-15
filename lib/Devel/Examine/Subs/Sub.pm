package Devel::Examine::Subs::Sub;

use Devel::Trace::Subs qw(trace trace_dump); # injected by Devel::Trace::Subs
use strict;
use warnings;

use Data::Dumper;

our $VERSION = '1.32';

sub new {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    my $class = shift;
    my $data = shift;
    my $name = shift;

    my $self = bless {}, $class;

    $self->{data} = $data;
    $self->{data}{name} = $name || '';

    return $self;
}
sub name {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};
    my $self = shift;
    return $self->{data}{name};
}
sub start {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};
    my $self = shift;
    return $self->{data}{start};
}
sub end {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};
    my $self = shift;
    return $self->{data}{end};
}
sub line_count {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};
    my $self = shift;
    return $self->{data}{num_lines};
}
sub lines {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    my $self = shift;

    my @line_linenum;

    if ($self->{data}{lines_with}){
        my $lines_with = $self->{data}{lines_with};
        
        for (@$lines_with){
            for my $num (keys %$_){
                push @line_linenum, "$num: $_->{$num}";
            }
        }
    }

    return \@line_linenum;
}
sub code {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    my $self = shift;

    my $code = $self->{data}{TIE_file_sub};

    return $code;
}
1;
