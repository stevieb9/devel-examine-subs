package Devel::Examine::Subs::Sub;

use strict;
use warnings;

our $VERSION = '1.18';

sub new {
    my $class = shift;
    my $data = shift;

    my $self = bless {}, $class;

    $self->{data} = $data;
    $self->{name} = $name || '';
    $self->{start_line} = $data->{start};
    $self->{stop_line} = $data->{stop};
    if ($data->{stop} and $data->{start}){
        $self->{count_line} = $data->{stop} - $data->{start};
    }
             
    return $self;
}
sub name {
    my $self = shift;
    return $self->{name};
}
sub start {
    my $self = shift;
    return $self->{start_line};
}
sub stop {
    my $self = shift;
    return $self->{stop_line};
}
sub count {
    my $self = shift;
    return $self->{count_line};
}
1;
