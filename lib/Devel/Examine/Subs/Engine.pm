package Devel::Examine::Subs::Engine;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Devel::Examine::Subs::Sub;
use File::Copy;
use Tie::File;

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
        objects =>\&objects,
        search_replace => \&search_replace,
        dt_test => \&dt_test,
        _test => \&_test,
        _test_print => \&_test_print,
        _test_bad => \&_test_bad,
    };

    return $dt;
}
sub _test {

    return sub {
        return {a => 1};
    };
}
sub _test_print {

    return sub {
        print "Hello, world!\n";
    };
}
sub all {

    return sub {

        my $p = shift;
        my $struct = shift;

        my $file = $p->{file};

        my @subs = keys %{$struct->{$file}{subs}};

        return \@subs;
    };
}
sub has {

    return sub {

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
                    next if not $search;
                    if ($code and $code =~ /$search/){
                        push @has, $sub;
                        $found = 1;
                    }
                    next if $found;
                }
            }
        }
        return \@has;
    };
}
sub missing {

    return sub {

        my $p = shift;
        my $struct = shift;

        my $file = $p->{file};
        my $search = $p->{search};

        return [] if not $search;

        my @missing;
        my @has;

        for my $file (keys %$struct){
            for my $sub (keys %{$struct->{$file}{subs}}){
                my @code = @{$struct->{$file}{subs}{$sub}{TIE_perl_file_sub}};
                if (! grep(/$search/, @code)){
                    push @missing, $sub;
                }
            }
        }
        return \@missing;
    };
}
sub lines {

    return sub {
        
        my $p = shift;
        my $struct = shift;

        my %return;

        for my $file (keys %$struct){
            for my $sub (keys %{$struct->{$file}{subs}}){
                my $line_num = $struct->{$file}{subs}{$sub}{start};
                my @code = @{$struct->{$file}{subs}{$sub}{TIE_perl_file_sub}};
                for my $line (@code){
                    $line_num++;
                    push @{$return{$sub}}, {$line_num => $line};
                }
            }
        }
        return \%return;
    };
}
sub search_replace {

    return sub {
        my $p = shift;
        my $struct = shift;
        my $des = shift;
    
        my $search = $p->{search};
        my $replace = $p->{replace};
        my $copy = $p->{copy};

        if (! $search){
            croak "Can't use search_replace engine without specifying a search term";
        }
        if (! $replace){
            croak "Can't use search_replace engine without specifying a replace term";
        }
        
        my $file = $p->{file};
 
        copy $file, "$file.bak";

        unlink $copy if -f $copy;
        
        if ($copy){
            copy $file, $copy;
            $file = $copy;
        }
       
        my @changed_lines;
        
        for my $sub (@$struct){
            my $start_line = $sub->start();
            my $end_line = $sub->end();

            tie my @tie_file, 'Tie::File', $file;

            my $line_num = 0;

            for my $line (@tie_file){
                $line_num++;
                if ($line_num < $start_line){
                    next;
                }
                if ($line_num > $end_line){
                    last;
                }
                
                if ($line =~ /$search/){
                    my $orig = $line;
                    $line =~ s/$search/$replace/g;
                    push @changed_lines, [$orig, $line];
                }
            }
            untie @tie_file;
        }
        return \@changed_lines;
    };                        
}
sub _nothing {}; # vim placeholder
