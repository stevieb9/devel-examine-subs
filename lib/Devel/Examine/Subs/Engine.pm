package Devel::Examine::Subs::Engine;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Devel::Examine::Subs;
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
        inject_after => \&inject_after,
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
                    if ($code and $code =~ /\Q$search/){
                        push @has, $sub;
                        $found = 1;
                    }
                    last if $found;
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

        for my $file (keys %$struct){
            for my $sub (keys %{$struct->{$file}{subs}}){
                my @code = @{$struct->{$file}{subs}{$sub}{TIE_perl_file_sub}};

                my @clean;

                for (@code){
                    push @clean, $_ if $_;
                } 

                if (! grep {/\Q$search/ and $_} @clean){
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
            print "\nDevel::Examine::Subs::Engine::search_replace speaking:\n" .
                  "can't use search_replace engine without specifying a search term\n\n";
            confess;
        }
        if (! $replace){
            print "\nDevel::Examine::Subs::Engine::search_replace speaking:\n" .
                  "can't use search_replace engine without specifying a replace term\n\n";
            confess;
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
                
                if ($line =~ /\Q$search/){
                    my $orig = $line;
                    $line =~ s/\Q$search/$replace/g;
                    push @changed_lines, [$orig, $line];
                }
            }
            untie @tie_file;
        }
        return \@changed_lines;
    };                        
}
sub inject_after {

    return sub {

        my $p = shift;
        my $struct = shift;
    
        my $search = $p->{search};
        my $code = $p->{code};
        my $copy = $p->{copy};

        if (! $search){
            confess "\nDevel::Examine::Subs::Engine::inject_after speaking:\n" .
                    "can't use inject_after engine without specifying a search term\n\n";
        }
        if (! $code){
            confess "\nDevel::Examine::Subs::Engine::inject_after speaking:\n" .
                    "can't use inject_after engine without code to inject\n\n";

        }
        
        my $file = $p->{file};
 
        copy $file, "$file.bak";

        unlink $copy if -f $copy;
        
        if ($copy){
            copy $file, $copy;
            $file = $copy;
        }

        my @unprocessed;       
        my @processed;
        
        for my $sub (@$struct){
            push @unprocessed, $sub->name();
        }

        for my $uname (@unprocessed){
        
            my $des = Devel::Examine::Subs->new();

            my $params = {
                        file => $file,
                        pre_filter => 'subs && objects',
                        pre_filter_return => 2,
                        search => $search,
            };

            my $struct = $des->run($params); 

            for my $sub (@$struct){

                next unless $sub->name() eq $uname;

                push @processed, $sub->name();
                
                my $start_line = $sub->start();
                my $end_line = $sub->end();
            
                tie my @tie_file, 'Tie::File', $file;

                my $line_num = 0;
                my $new_lines = 0; # don't search added lines

                for my $line (@tie_file){
                    $line_num++;

                    if ($line_num < $start_line){
                        next;
                    }
                    if ($line_num > $end_line){
                        last;
                    }
                    
                    if ($line =~ /\Q$search/ && ! $new_lines){
                        
                        my $location = $line_num;

                        my $indent;

                        if (! $p->{no_indent}){
                            if ($line =~ /^(\s+)/ && $1){
                                $indent = $1;
                            }
                        }
                        for my $line (@$code){
                            splice @tie_file, $location++, 0, $indent . $line; 
                            $new_lines++;
                        }
                        splice @tie_file, $location++, 0, '';
                    }
                    $new_lines-- if $new_lines != 0;
                }
                untie @tie_file;
            }
        }
        return \@processed;
    };                        
}

sub _nothing {}; # vim placeholder
