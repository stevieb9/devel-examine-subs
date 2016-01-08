package Devel::Examine::Subs::Preprocessor;
use 5.008;
use strict;
use warnings;

our $VERSION = '1.59';

use Carp;
use Data::Dumper;

BEGIN {

    # we need to do some trickery for DTS due to a circular install

    eval {
        require Devel::Trace::Subs;
        import Devel::Trace::Subs qw(trace);
    };

    if ($@ && ! exists $Devel::Examine::Subs{'trace'}){
        *trace = sub {};
    }
};

sub new {

    trace() if $ENV{TRACE};

    my $self = {};
    bless $self, shift;

    my $struct = shift;

    $self->{pre_procs} = $self->_dt;

    return $self;
}
sub _dt {

    trace() if $ENV{TRACE};

    my $self = shift;

    my $dt = {
        module => \&module,
        inject => \&inject,
        remove => \&remove,
        replace => \&replace,
        _test_bad => \&test_bad,
    };

    return $dt;
}
sub exists {

    trace() if $ENV{TRACE};

    my $self = shift;
    my $string = shift;

    if (exists $self->{pre_procs}{$string}){
        return 1;
    }
    else {
        return 0;
    }
}
sub module {

    trace() if $ENV{TRACE};

    return sub {
        trace() if $ENV{TRACE};

        no strict 'refs';

        my $p = shift;

        if (!$p->{module} or $p->{module} eq '') {
            return [];
        }

        (my $module_file = $p->{module}) =~ s|::|/|g;

        eval {
            require "$module_file.pm";
        };

        if ($@){
            die "Module $p->{module} not found: $!";
        }

        my $namespace = "$p->{module}::";

        my @subs;

        for my $sub (keys %$namespace){
            if (defined &{$namespace . $sub}){
                push @subs, $sub;
            }
        }

        return \@subs;
    };
}
sub inject {

    trace() if $ENV{TRACE};

    return sub {

        trace() if $ENV{TRACE};

        my $p = shift;

        my @file_contents = @{ $p->{file_contents} };

        # after line number

        my $rw = File::Edit::Portable->new;

        if (defined $p->{line_num}){
           
            # inject after line number

            $rw->splice(
                file => $p->{file},
                line => $p->{line_num},
                insert => $p->{code},
                copy => $p->{copy},
            );
        }
        elsif ($p->{inject_use}){  
            
            # inject a use statement

            my $use = qr/use\s+\w+/;
            
            my $index;

            ($index) = grep {
                $file_contents[$_] =~ $use
            } 0..$#file_contents;

            if (!$index) {
                ($index) = grep {
                    $file_contents[$_] =~ /^package\s+\w+/
                } 0..$#file_contents;
                $index++;
            }

            if ($index) {
                $rw->splice(
                    file => $p->{file},
                    line => $index,
                    insert => $p->{inject_use},
                    copy => $p->{copy},
                );
            }
        }
        elsif ($p->{inject_after_sub_def}){

            # inject code after sub definition

            my $code = $p->{inject_after_sub_def};

            my @new_file;

            my $single_line = qr/
                sub\s+\w+\s*(?:\(.*?\)\s+)?\{\s*(?!\s*[\S])
                |
                sub\s+\{\s*(?!\s*[\S])
                /x;

            my $multi_line = qr/sub\s+\w+\s*(?![\S])/;

            my $is_multi = 0;

            my $i = -1;

            for my $e (@file_contents){

                $i++;

                if ($e =~ /^\n/){
                    push @new_file, "\n";
                }

                my $indent = '';

                my $count = $i;
                $count++;

                while ($count < @file_contents){
                    if ($file_contents[$count] =~ /^(\s*)\S/){
                        $indent = $1;
                        last;
                    }
                    else {
                        $count++;
                    }
                }

                push @new_file, $e;

                if ($e =~ $single_line) {
                    for (@$code){
                        push @new_file, $indent . $_;
                    }
                }
                elsif ($e =~ $multi_line) {
                    if ($file_contents[$count] =~ /\s*\{\s*(?!\s*[\S])/) {
                        $is_multi = 1;
                        next;
                    }
                }

                if ($is_multi) {
                    for (@$code) {
                        push @new_file, $indent . $_;
                    }
                    $is_multi = 0;
                }
            }
            $p->{write_file_contents} = \@new_file;
        }
    }
}
sub replace {

    trace() if $ENV{TRACE};

    return sub {

        trace() if $ENV{TRACE};

        my $p = shift;
        my $exec = $p->{exec};
        my $limit = defined $p->{limit} ? $p->{limit} : -1;

        my @file = @{ $p->{file_contents} };

        if (! $exec || ref $exec ne 'CODE'){
            croak "\nDES::replace() requires 'exec => \$cref param\n";
        }

        my $lines_changed;

        for (@file){
            my $changed = $exec->($_);
            if ($changed){
                $lines_changed++;
                $limit--;
                last if $limit == 0;
            }
        }

        $p->{write_file_contents} = \@file;
        return $lines_changed;
    }
}
sub remove {

    trace() if $ENV{TRACE};

    return sub {

        trace() if $ENV{TRACE};
        
        my $p = shift;
        my @file = @{ $p->{file_contents}};

        my $delete = $p->{delete};

        for my $find (@$delete){
            while (my ($index) = grep { $file[$_] =~ $find } 0..$#file){
                splice @file, $index, 1;
            }
        }
        $p->{write_file_contents} = \@file;
    }
}

1;


sub _vim_placeholder {1;}

__END__

=head1 NAME

Devel::Examine::Subs::Preprocessor - Provides core pre_proc callbacks for
Devel::Examine::Subs

=head1 SYNOPSIS

    use Devel::Examine::Subs::Preprocessor;

    my $compiler = Devel::Examine::Subs::Preprocessor->new;

    my $pre_proc = 'module';

    if (! $compiler->exists($pre_proc)){
        croak "pre_proc $pre_proc is not implemented.\n";
    }

    eval {
        $pre_proc_cref = $compiler->{pre_procs}{$pre_proc}->();
    };

=head1 DESCRIPTION

Pre-processors run prior to the main processing routine that does the file
reading and subroutine compilations.

Use a pre-processor to manipulate the system early in the call chain, or get
and return data that doesn't require reading any files.

Use C<Devel::Examine::Subs> C<pre_proc_return> parameter to return the data
after the pre-processor has run to avoid unnecessary work by the processor.

=head1 METHODS

All methods other than C<exists()> takes an href of configuration data as its
first parameter.

=head2 C<exists('pre_proc')>

Verifies whether the engine name specified as the string parameter exists and
is valid.


=head2 C<module>

Mandatory parameters: C<{ module =E<gt> 'Module::Name' }>

This pre-processor returns an array reference of all subroutines within the
namespace of the module listed in the C<module> parameter.

The data is returned early as mentioned in the L<DESCRIPTION>.

=head2 C<inject>

Parameters: C<{ inject_use =E<gt> ['use statement1;', 'use statement2;'] }>
or C<{ inject_after_sub_def =E<gt> ['code line 1;', 'code line 2;'] }> or C<{ line_num =E<gt> $num, code => \@code }>

Injects each element of the array ref as either a use statement, lines of code after a sub definition, or a block of code immediately after the line number.

=head2 C<remove>

Parameters: C<delete =E<gt> 'string'>

Deletes the entire line of code, if it contains 'string'.


=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Examine::Subs

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


