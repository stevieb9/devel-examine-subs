package Devel::Examine::Subs::Engine;

use strict;
use warnings;

use Data::Dumper;

our $VERSION = '1.18';

# new

sub new {
    my $self = {};
    bless $self, shift;

    $self->{engines} = $self->_dt();

    return $self;
}

sub _dt {
    my $self = shift;

    my $dt = {
        all => \&all,
        has => \&has,
        missing => \&missing,
        lines => \&lines,
        _test => \&_test,
        _test_print => \&_test_print,
        _search_legacy => \&_search_legacy,
    };

    return $dt;
}
            
sub _test {
    return {a => 1};
}

sub _test_print {
    print "Hello, world!\n";
}

sub all {
    my $p = shift;
    my $struct = shift;

    my $file = $p->{file};

    my @subs = keys %{$struct->{$file}{subs}};

    return \@subs;
}

sub has {
    my $p = shift;
    my $struct = shift;

    my $file = $p->{file};
    my $search = $p->{search};

    my @has;

    for my $file (keys %$struct){
        for my $sub (keys %{$struct->{$file}{subs}}){
            my $found = 0;

            my @code_block = @{$struct->{$file}{subs}{$sub}{TIE_perl_file_sub}};
            for my $code (@code_block){
                for my $line (@$code){
                    next if not $search;
                    if ($line and $line =~ /$search/){
                        push @has, $sub;
                        $found = 1;
                        last;
                    }
                }
                next if $found;
            }
        }
    }

    return \@has;
}

sub missing {
    my $p = shift;
    my $struct = shift;

    my $file = $p->{file};
    my $search = $p->{search};

    return [] if not $search;

    my @missing;
    my @has;

    for my $file (keys %$struct){
        for my $sub (keys %{$struct->{$file}{subs}}){

            my @code_block = @{$struct->{$file}{subs}{$sub}{TIE_perl_file_sub}};
            for my $code (@code_block){
                if (! grep(/$search/, @$code)){
                    push @missing, $sub;
                }
            }
        }
    }
    return \@missing;
}

sub lines {
    my $p = shift;
    my $struct = shift;

    my %return;

    for my $file (keys %$struct){
        for my $sub (keys %{$struct->{$file}{subs}}){
            my @code_block = @{$struct->{$file}{subs}{$sub}{TIE_perl_file_sub}};
            for my $code (@code_block){
                my $line_num = $struct->{$file}{subs}{$sub}{start};
                for (@$code){
                    $line_num++;
                    push @{$return{$sub}}, {$line_num => $_};
                }
            }
        }
    }
    return \%return;
}
sub _nothing {}; # vim placeholder
