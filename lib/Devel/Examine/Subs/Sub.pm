package Devel::Examine::Subs::Sub;

use strict;
use warnings;

our $VERSION = '1.18';

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
1;
