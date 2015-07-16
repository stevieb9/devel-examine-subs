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
        _default => \&_default,
        _test => \&_test,
        object => \&object,
    };

    return $dt;
}
            
# _test

sub _test {
    my $struct = shift;
    return $struct;
}

# _default

sub object {
    my $des = shift;
    my $struct = shift;

    my %return;

    for my $file (keys %$struct){
        $return{$file} = $des->_objects($struct->{$file});
    }
    
    return \%return;
}

__END__

# _search_legacy

sub _search_legacy {

    my $self = shift;
    my $p = shift;

    my $search = $p->{search};
    my %subs = %{$p->{subs}};

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
