package Devel::Examine::Subs::Engine;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Devel::Examine::Subs;
use Devel::Examine::Subs::Sub;
use File::Copy;
use Tie::File;

our $VERSION = '1.23';

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
        objects => \&objects,
        search_replace => \&search_replace,
        inject_after => \&inject_after,
        dt_test => \&dt_test,
        _test => \&_test,
        _test_print => \&_test_print,
        _test_bad => \&_test_bad,

    };

    return $dt;
}
sub exists {
    my $self = shift;
    my $string = shift;

    if (exists $self->{engines}{$string}){
        return 1;
    }
    else {
        return 0;
    }
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

        return [] if ! $struct;

        my $file = (keys %$struct)[0];

        my @has = keys %{$struct->{$file}{subs}};

        return \@has || [];
    };
}
sub missing {

    return sub {

        my $p = shift;
        my $struct = shift;

        my $file = $p->{file};
        my $search = $p->{search};
 
        if ($search && ! $p->{regex}){
            $search = "\Q$search";
        }
       
        return [] if not $search;

        my @missing;

        for my $file (keys %$struct){
            for my $sub (keys %{$struct->{$file}{subs}}){
                my @code = @{$struct->{$file}{subs}{$sub}{TIE_file_sub}};

                my @clean;

                for (@code){
                    push @clean, $_ if $_;
                } 

                if (! grep {/$search/ and $_} @clean){
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
                my @code = @{$struct->{$file}{subs}{$sub}{TIE_file_sub}};
                for my $line (@code){
                    $line_num++;
                    push @{$return{$sub}}, {$line_num => $line};
                }
            }
        }
        return \%return;
    };
}
sub objects {

    # uses 'subs' pre_filter

    return sub {

        my $p = shift;
        my $struct = shift;

        my @return;

        return if not ref($struct) eq 'ARRAY';

        my $file = $p->{file};
        my $search = $p->{search};

        if ($search && ! $p->{regex}){
            $search = "\Q$search";
        }

        my $lines;

        if ($search){
            my $des = Devel::Examine::Subs->new({
                                            file => $file, 
                                            search => $search
                                        });
            $lines = $des->lines();
        }

        my $des_sub;
        
        for my $sub (@$struct){

            # if the name of the callback method is mistyped in the
            # dispatch table, this will be triggered

            if ($lines){
                $sub->{lines_with} = $lines->{$sub->{name}};
            }

            $des_sub
              = Devel::Examine::Subs::Sub->new($sub, $sub->{name});

            #FIXME: this eval catch catches bad dispatch and "not a hashref"

            if ($@){
                print "dispatch table in engine has a mistyped function value\n\n";
                confess $@;
            }

            push @return, $des_sub;
        }

        return \@return;
    };
}
sub search_replace {

    return sub {

        my $p = shift;
        my $struct = shift;
        my $des = shift;

        my $file = $p->{file};
        my $search = $p->{search};
        
        if ($search && ! $p->{regex}){
            $search = "\Q$search";
        }

        my $replace = $p->{replace};
        my $copy = $p->{copy} if $p->{copy};

        if (! $file){
            croak "\nDevel::Examine::Subs::Engine::search_replace speaking:\n" .
                  "can't use search_replace engine without specifying a file\n\n";
        }

        if (! $search){
            croak "\nDevel::Examine::Subs::Engine::search_replace speaking:\n" .
                  "can't use search_replace engine without specifying a search term\n\n";
        }
        if (! $replace){
            croak "\nDevel::Examine::Subs::Engine::search_replace speaking:\n" .
                  "can't use search_replace engine without specifying a replace term\n\n";
        }
        
 
        copy $file, "$file.bak";

        if ($copy && -f $copy){
            unlink $copy;
        }
        
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
sub inject_after {

    return sub {

        my $p = shift;
        my $struct = shift;
    
        my $search = $p->{search};

        if ($search && ! $p->{regex}){
            $search = "\Q$search";
        }

        my $num_injects = $p->{injects} // 1;
        my $code = $p->{code};
        my $copy = $p->{copy};

        if (! $search){
            croak "\nDevel::Examine::Subs::Engine::inject_after speaking:\n" .
                    "can't use inject_after engine without specifying a search term\n\n";
        }
        if (! $code){
            croak "\nDevel::Examine::Subs::Engine::inject_after speaking:\n" .
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

                    if ($line =~ /$search/ && ! $new_lines){
                       
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
                            $end_line++;
                        }
                        splice @tie_file, $location++, 0, '';

                        # stop injecting after N search finds

                        $num_injects--;
                        
                        if ($num_injects == 0){
                            untie @tie_file;
                            last;
                        }
                        
                    }
                    $new_lines-- if $new_lines != 0;
                }
                untie @tie_file;
            }
        }
        return \@processed;
    };                        
}
1;
sub _vim_placeholder {}

__END__

=head1 NAME

Devel::Examine::Subs::Engine - Provides core engine callbacks for Devel::Examine::Subs

=head1 SYNOPSIS

    use Devel::Examine::Subs::Engine;

    my $compiler = Devel::Examine::Subs::Engine->new();

    if (! $compiler->exists($engine)){
        croak "engine '$engine' is not implemented.\n";
    }

    eval {
        $engine_cref = $compiler->{engines}{$engine}->();
    };


=head1 METHODS

All methods other than C<exists()> takes an href of configuration data as it's first parameter.

=head2 C<exists('engine')>

Verifies whether the engine name specified as the string parameter exists and is valid.

=head2 C<all()>

Takes C<$struct> params directly from the Processor module.

Returns an aref.

=head2 C<has()>

Takes C<$struct> from the output of the 'file_lines_contain' Pre-filter.

Returns an aref.

=head2 C<missing()>

Data comes directly from the Processor.

Returns an aref.

=head2 C<lines()>

The module that passes data in is dependant on whether 'search' is set. Otherwise, it comes directly from the Processor.

Returns an href.

=head2 C<objects()>

Uses C<Devel::Examine::Subs::Sub> to generate objects based on subs.

Returns an aref of said objects.

=head2 C<search_replace()>

Takes params, struct and a des object.

Returns aref of replaced lines if there are any.

=head2 C<inject_after()>

Returns aref of subs that had code injected.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Examine::Subs

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU General Public License as 
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


