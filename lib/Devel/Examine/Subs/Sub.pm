package Devel::Examine::Subs::Sub;

use strict;
use warnings;

use Data::Dumper;

our $VERSION = '1.28';

sub new {

    my $class = shift;
    my $data = shift;
    my $name = shift;

    my $self = bless {}, $class;

    $self->{data} = $data;
    $self->{data}{name} = $name || '';

    return $self;
}
sub name {
    my $self = shift;
    return $self->{data}{name};
}
sub start {
    my $self = shift;
    return $self->{data}{start};
}
sub end {
    my $self = shift;
    return $self->{data}{end};
}
sub line_count {
    my $self = shift;
    return $self->{data}{num_lines};
}
sub lines {

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

    my $self = shift;

    my $code = $self->{data}{TIE_file_sub};

    return $code;
}
1;
