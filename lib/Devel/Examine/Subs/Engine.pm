package Devel::Examine::Subs::Engine;

use strict;
use warnings;

our $VERSION = '1.18';

# new

sub new {
    my $self = {};
    bless $self, shift;

    $self->{engines} = $self->_dt();

    return $self;
}

# engine dispatch

sub _dt {
    my $self = shift;

    my $dt = {
        _test => \&_test,
        _test_print => \&_test_print,
        _search_legacy => \&_search_legacy,
    };

    return $dt;
}
            
# _test

sub _test {
    return {a => 1};
}

# _test_print

sub _test_print {
    print "Hello, world!\n";
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
