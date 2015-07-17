package Devel::Examine::Subs::Prefilter;

use strict;
use warnings;

use Data::Dumper;

our $VERSION = '1.18';

# new

sub new {
    my $self = {};
    bless $self, shift;

    my $struct = shift;

    $self->{pre_filters} = $self->_dt();

    return $self;
}

# pre_filter dispatch

sub _dt {
    my $self = shift;

    my $dt = {
        file_lines_contain => \&file_lines_contain,
        _default => \&_default,
        _test => \&_test,
        object => \&object,
    };

    return $dt;
}
           
sub file_lines_contain {
    my $p = shift;
    my $struct = shift;

    my $search = $p->{search};

    my $s = $struct;
    my @has;


    if (not $search){
        return $struct;
    }

    for my $f (keys %$s){
        for my $sub (keys %{$s->{$f}{subs}}){
            for (@{$s->{$f}{subs}{$sub}{TIE_perl_file_sub}}){
                for (@$_){
                    if ($_ and /$search/){
                        push @has, $_;
                    }
                }
            }
            $s->{$f}{subs}{$sub}{TIE_perl_file_sub} = [\@has];
        }
    }

    return $struct;
}
sub _test {
    my $struct = shift;
    return $struct;
}

__END__
sub object {
    my $des = shift;
    my $struct = shift;

    my %return;

    for my $file (keys %$struct){
        $return{$file} = $des->_objects($struct->{$file});
    }
    
    return \%return;
}


    if (not $search eq ''){
        
        # pull out just the subroutine from the file array

        my @sub_section = @fh[$subs{$name}{start}..$subs{$name}{stop}];
       
        my $line_num = $subs{$name}{start};
        
        for (@sub_section){
           
            # we havent found the search term yet

            $subs{$name}{found} = 0;

            if ($_ and /$search/){
                if ($want ne 'has_lines'){
                    $subs{$name}{found} = 1;
                }
                else {
                    push @{$subs{$name}{lines}}, {$line_num => $_};
                }
            }

            $line_num++;
            last if $subs{$name}{found};
        }
    }
    else { 
        return {};
    }

    return \%subs;
}

1;
