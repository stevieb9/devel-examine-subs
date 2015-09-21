package Devel::Examine::Subs::Engine 1.39;
use 5.012;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use Devel::Examine::Subs;
use Devel::Examine::Subs::Sub;
use File::Copy;

BEGIN {

    # we need to do some trickery for DTS due to a circular install

    eval {
        require Devel::Trace::Subs;
        import Devel::Trace::Subs qw(trace);
    };

    if ($@){

        # override DTS's trace() function if necessary
        *trace = sub {};
    }
};

sub new {
    
    trace() if $ENV{TRACE};

    my $self = {};
    bless $self, shift;

    $self->{engines} = $self->_dt;

    return $self;
}
sub _dt {
    
    trace() if $ENV{TRACE};

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
    
    trace() if $ENV{TRACE};

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
    
    trace() if $ENV{TRACE};

    return sub {
        trace() if $ENV{TRACE};
        return {a => 1};
    };
}
sub _test_print {
    
    trace() if $ENV{TRACE};

    return sub {
        
        trace() if $ENV{TRACE};
        print "Hello, world!\n";
    };
}
sub all {
    
    trace() if $ENV{TRACE};

    return sub {
        
        trace() if $ENV{TRACE};

        my $p = shift;
        my $struct = shift;

        my $file = $p->{file};

        my @subs = keys %{$struct->{$file}{subs}};

        return \@subs;
    };
}
sub has {
    
    trace() if $ENV{TRACE};

    return sub {
        
        trace() if $ENV{TRACE};
        
        my $p = shift;
        my $struct = shift;

        return [] if ! $struct;

        my $file = (keys %$struct)[0];

        my @has = keys %{$struct->{$file}{subs}};

        return \@has || [];
    };
}
sub missing {
    
    trace() if $ENV{TRACE};

    return sub {
        
        trace() if $ENV{TRACE};

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
                my @code = @{$struct->{$file}{subs}{$sub}{contents}};

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
    
    trace() if $ENV{TRACE};

    return sub {
        
        trace() if $ENV{TRACE};
        
        my $p = shift;
        my $struct = shift;

        my %return;

        for my $file (keys %$struct){
            for my $sub (keys %{$struct->{$file}{subs}}){
                my $line_num = $struct->{$file}{subs}{$sub}{start};
                my @code = @{$struct->{$file}{subs}{$sub}{contents}};
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
    
    trace() if $ENV{TRACE};

    # uses 'subs' pre_filter

    return sub {
        
        trace() if $ENV{TRACE};

        my $p = shift;
        my $struct = shift;


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
            $lines = $des->lines;
        }

        my $des_sub;
        my %obj_hash;
        my @obj_array;

        for my $sub (@$struct){

            if ($lines){
                $sub->{lines_with} = $lines->{$sub->{name}};
            }

            $des_sub
              = Devel::Examine::Subs::Sub->new($sub, $sub->{name});

            if ($p->{objects_in_hash}){
                $obj_hash{$sub->{name}} = $des_sub;
            }
            else {
                push @obj_array, $des_sub;
            }
        }

        if ($p->{objects_in_hash}){
            return \%obj_hash;
        }
        else {
            return \@obj_array;
        }
    };
}
sub search_replace {

    trace() if $ENV{TRACE};

    return sub {

        trace() if $ENV{TRACE};

        my $p = shift;
        my $struct = shift;

        my $file = $p->{file};
        my @file_contents = @{ $p->{file_contents} } if $p->{file_contents};
        my $search = $p->{search};
        
        if ($search && ! $p->{regex}){
            $search = "\Q$search";
        }

        my $replace = $p->{replace};

        if (! $file){
            croak "\nDevel::Examine::Subs::Engine::search_replace " .
                  "speaking:\n" .
                  "can't use search_replace engine without specifying a " .
                  "file\n\n";
        }

        if (! $search){
            croak "\nDevel::Examine::Subs::Engine::search_replace " .
                  " speaking:\n" .
                  "can't use search_replace engine without specifying a " .
                  "search term\n\n";
        }
        if (! $replace){
            croak "\nDevel::Examine::Subs::Engine::search_replace " .
                  "speaking:\n" .
                  "can't use search_replace engine without specifying a " .
                  "replace term\n\n";
        }
        
 
        my @changed_lines;
        
        for my $sub (@$struct){

            my $start_line = $sub->start;
            my $end_line = $sub->end;

            my $line_num = 0;

            for my $line (@file_contents){

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
        }

        $p->{write_file_contents} = \@file_contents;

        return \@changed_lines;
    };                        
}
sub inject_after {
    
    trace() if $ENV{TRACE};

    return sub {
        
        trace() if $ENV{TRACE};

        my $p = shift;
        my $struct = shift;

        my $search = $p->{search};

        if ($search && !$p->{regex}) {
            $search = "\Q$search";
        }

        my $code = $p->{code};

        if (!$search) {
            croak "\nDevel::Examine::Subs::Engine::inject_after speaking:\n" .
                "can't use inject_after engine without specifying a " .
                "search term\n\n";
        }
        if (!$code) {
            croak "\nDevel::Examine::Subs::Engine::inject_after speaking:\n" .
                "can't use inject_after engine without code to inject\n\n";

        }

        my $file = $p->{file};
        my @file_contents = @{$p->{file_contents}};

        my @processed;

        my $added_lines = 0;

        my @subs;

        for my $sub (@$struct) {
            push @subs, $sub->name;
        }

        my $des = Devel::Examine::Subs->new(file => $p->{file});
        my $subs_hash = $des->objects(objects_in_hash => 1, include => \@subs);

        my @sorted_subs = sort {
                $subs_hash->{$a}->start <=> $subs_hash->{$b}->start
            } keys %$subs_hash;

        for (@sorted_subs){

            my $sub = $subs_hash->{$_};

            my $num_injects = $p->{injects} // 1;

            push @processed, $sub->name;

            my $start_line = $sub->start;
            my $end_line = $sub->end;

            $start_line += $added_lines;
            $end_line += $added_lines;

            my $line_num = 0;
            my $new_lines = 0; # don't search added lines

            for my $line (@file_contents){
                $line_num++;
                if ($line_num < $start_line){
                    next;
                }
                if ($line_num > $end_line){
                    last;
                }

                if ($line =~ /$search/ && ! $new_lines){

                    my $location = $line_num;

                    my $indent = '';

                    if (! $p->{no_indent}){
                        if ($line =~ /^(\s+)/ && $1){
                            $indent = $1;
                        }
                    }
                    for (@$code){
                        splice @file_contents, $location++, 0, $indent . $_;
                        $new_lines++;
                        $added_lines++;
                    }

                    # stop injecting after N search finds

                    $num_injects--;
                    if ($num_injects == 0){
                        last;
                    }

                }
                $new_lines-- if $new_lines != 0;
            }
        }
        $p->{write_file_contents} = \@file_contents;
        return \@processed;
    };                        
}
1;

sub _vim_placeholder {}

__END__

=head1 NAME

Devel::Examine::Subs::Engine - Provides core engine callbacks for
Devel::Examine::Subs

=head1 SYNOPSIS

    use Devel::Examine::Subs::Engine;

    my $compiler = Devel::Examine::Subs::Engine->new;

    my $engine = 'has';

    if (! $compiler->exists($engine)){
        croak "engine $engine is not implemented.\n";
    }

    eval {
        $engine_cref = $compiler->{engines}{$engine}->();
    };


=head1 METHODS

All methods other than C<exists()> takes an href of configuration data as its
first parameter.

=head2 C<exists('engine')>

Verifies whether the engine name specified as the string parameter exists and
is valid.

=head2 C<all>

Takes C<$struct> params directly from the Processor module.

Returns an aref.

=head2 C<has>

Takes C<$struct> from the output of the 'file_lines_contain' Pre-filter.

Returns an aref.

=head2 C<missing>

Data comes directly from the Processor.

Returns an aref.

=head2 C<lines>

The module that passes data in is dependant on whether 'search' is set.
Otherwise, it comes directly from the Processor.

Returns an href.

=head2 C<objects>

Uses C<Devel::Examine::Subs::Sub> to generate objects based on subs.

Returns an aref of said objects.

=head2 C<search_replace>

Takes params, struct and a des object.

Returns aref of replaced lines if there are any.

=head2 C<inject_after>

Returns aref of subs that had code injected.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Examine::Subs

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


