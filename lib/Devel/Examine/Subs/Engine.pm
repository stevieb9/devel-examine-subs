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

sub _nothing {}; # vim placeholder

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
