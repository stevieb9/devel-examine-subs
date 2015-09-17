package Devel::Examine::Subs::Prefilter;
use strict;
use warnings;

use Carp;
use Data::Dumper;

our $VERSION = '1.35';

BEGIN {

    # we need to do some trickery for DTS due to a circular install

    eval {
        require Devel::Trace::Subs;
        import Devel::Trace::Subs qw(trace);
    };

    if ($@){
        *trace = sub {};
    }
};

sub new {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    my $self = {};
    bless $self, shift;

    my $struct = shift;

    $self->{pre_filters} = $self->_dt();

    return $self;
}
sub _dt {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    my $self = shift;

    my $dt = {
        file_lines_contain => \&file_lines_contain,
        subs => \&subs,
        objects => \&objects,
        _default => \&_default,
        _test => \&_test,
        _test_bad => \&_test_bad,
        end_of_last_sub => \&end_of_last_sub,
    };

    return $dt;
}
sub exists {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    my $self = shift;
    my $string = shift;

    if (exists $self->{pre_filters}{$string}){
        return 1;
    }
    else {
        return 0;
    }
}
sub subs {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};
    
    return sub {
        trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

        my $p = shift;
        my $struct = shift;
        
        my $s = $struct;
        my @subs;

        my $search = $p->{search};

        if ($search && ! $p->{regex}){
            $search = "\Q$search";
        }

        for my $f (keys %$s){
        
            for my $sub (keys %{$s->{$f}{subs}}){
                
                if ($search && $sub eq $search){
                    next;
                }
                $s->{$f}{subs}{$sub}{start}++;
                $s->{$f}{subs}{$sub}{end}++;
                $s->{$f}{subs}{$sub}{name} = $sub;
                @{ $s->{$f}{subs}{$sub}{file} } = @{ $s->{$f}{TIE_file} };
                push @subs, $s->{$f}{subs}{$sub};
            }
        }
        return \@subs;
    };
}
sub file_lines_contain {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    return sub {
        trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

        my $p = shift;
        my $struct = shift;

        my $search = $p->{search};

        if ($search && ! $p->{regex}){
            $search = "\Q$search";
        }

        my $s = $struct;

        if (not $search){
            return $struct;
        }

        for my $f (keys %$s){
            for my $sub (keys %{$s->{$f}{subs}}){
                my $found = 0;
                my @has;
                for (@{$s->{$f}{subs}{$sub}{TIE_file_sub}}){
                    if ($_ and /$search/){
                        $found++;
                        push @has, $_;
                     }
                }
                if (! $found){
                    delete $s->{$f}{subs}{$sub};                
                    next;
                }
                $s->{$f}{subs}{$sub}{TIE_file_sub} = \@has;
            }
        }
        return $struct;
    };
}
sub end_of_last_sub {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};
    
    return sub {
        trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};
        
        my $p = shift;
        my $struct = shift;

        my @last_line_nums;

        for my $sub (@$struct){
            push @last_line_nums, $sub->{end};
        }

        @last_line_nums = sort {$a<=>$b} @last_line_nums;

        return $last_line_nums[-1];

    };
}
sub _test {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    return sub {
        trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};
        my $p = shift;
        my $struct = shift;
        return $struct;
    };
}
sub objects {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    # uses 'subs' pre_filter

    return sub {
        trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

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

        my $des_sub;

        for my $sub (@$struct){

            # if the name of the callback method is mistyped in the
            # dispatch table, this will be triggered

            $des_sub
              = Devel::Examine::Subs::Sub->new($sub, $sub->{name});

            #FIXME: this eval catch catches bad dispatch and "not a hashref"

            if ($@){
                print "dispatch table in engine has a mistyped function " .
                      "value\n\n";
                confess $@;
            }

            push @return, $des_sub;
        }

        return \@return;
    };
}
1;
sub _vim_placeholder {}

__END__

=head1 NAME

Devel::Examine::Subs::Prefilter - Provides core Pre-Filter callbacks for
Devel::Examine::Subs

=head1 DESCRIPTION

This module generates and supplies the core prefilter module callbacks.
Prefilters run after the core Processor, and before any Engine is run.

=head1 SYNOPSIS

Pre-filters can be daisy chained as text strings that represent a built-in
prefilter, or as callbacks, or both.

See C<Devel::Examine::Subs::_pre_filter()> for implementation details.

=head1 METHODS

All methods other than C<exists()> takes an href of configuration data as its
first parameter.

=head2 C<exists('prefilter')>

Verifies whether the prefilter name specified as the string parameter exists
and is valid.

=head2 C<subs()>

Returns an aref of hash refs, each containing info per sub.


=head2 C<file_lines_contain()>

Returns an aref similar to C<subs()>, but includes an array within each sub
href that contains lines that match a search term.

=head2 C<end_of_last_sub()>

Takes data from C<subs()>.

Returns a scalar containing the last line number of the last sub in a file.

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
