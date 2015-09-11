package Devel::Examine::Subs::Sub;

use strict;
use warnings;

use Data::Dumper;
use Devel::Trace::Flow qw(trace);

our $VERSION = '1.29';

sub new {
	trace();


    my $class = shift;
    my $data = shift;
    my $name = shift;

    my $self = bless {}, $class;

    $self->{data} = $data;
    $self->{data}{name} = $name || '';

    return $self;
}
sub name {
	trace();

    my $self = shift;
    return $self->{data}{name};
}
sub start {
	trace();

    my $self = shift;
    return $self->{data}{start};
}
sub end {
	trace();

    my $self = shift;
    return $self->{data}{end};
}
sub line_count {
	trace();

    my $self = shift;
    return $self->{data}{num_lines};
}
sub lines {
	trace();


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
	trace();


    my $self = shift;

    my $code = $self->{data}{TIE_file_sub};

    return $code;
}
1;
