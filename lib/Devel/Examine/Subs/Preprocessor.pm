package Devel::Examine::Subs::Preprocessor;

use strict;
use warnings;

use Carp;
use Data::Dumper;

our $VERSION = '1.37';

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

    $self->{pre_procs} = $self->_dt;

    return $self;
}

sub _dt {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    my $self = shift;

    my $dt = {
        module => \&module,
        inject => \&inject,
        remove => \&remove,
        _test_bad => \&test_bad,
    };

    return $dt;
}

sub exists {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};
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
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    return sub {
        trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

        no strict 'refs';

        my $p = shift;

        if (! $p->{module} or $p->{module} eq ''){
            return [];
        }

        (my $module_file = $p->{module}) =~ s|::|/|g;

        require "$module_file.pm"
          or croak "Module $p->{module} not found: $!";

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
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    return sub {
        trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

        my $p = shift;
        my $file = $p->{file};

        tie my @file, 'Tie::File', $file, recsep => $ENV{DES_EOL}
          or die $!;

        if ($p->{inject_use}) {

            my $use = qr/use\s+\w+/;

            my ($index) = grep {
                $file[$_] =~ $use
            } 0..$#file;

            if (!$index) {
                ($index) = grep {
                    $file[$_] =~ /^package\s+\w+/
                } 0..$#file;
            }

            if ($index) {
                for (@{$p->{inject_use}}) {
                    splice @file, $index, 0, $_;
                }
            }

            untie @file;

            return;
        }

        if ($p->{inject_after_sub_def}) {

            my $code = $p->{inject_after_sub_def};

            my @new_file;

            my $single_line = qr/
                sub\s+\w+\s*(?:\(.*?\)\s+)?\{\s*(?!\s*[\S])
                |
                sub\s+\{\s*(?!\s*[\S])
                /x;

            my $multi_line = qr/sub\s+\w+\s*(?![\S])/;

            my $is_multi = 0;

            while (my ($i, $e) = each @file){

                if ($e =~ /^\n/){
                    push @new_file, "\n";
                }

                my $indent = '';

                my $count = $i;
                $count++;

                while ($count < @file){
                    if ($file[$count] =~ /^(\s*)\S/){
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
                    if ($file[$count] =~ /\s*\{\s*(?!\s*[\S])/) {
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

            @file = @new_file;
        }
    }
}

sub remove {
    trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};

    return sub {
        trace() if $ENV{DTS_ENABLE} && $ENV{DES_TRACE};
        
        my $p = shift;
        my $file = $p->{file};        
        my $delete = $p->{delete};

        tie my @file, 'Tie::File', $file ,recsep => $ENV{DES_EOL} 
          or die $!; 
    
        for my $find (@$delete){
            while (my ($index) = grep { $file[$_] =~ $find } 0..$#file){
                splice @file, $index, 1;
            }
        }
        untie @file;

        return;
    }
}

1;


sub _vim_placeholder {}

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
or C<{ inject_after_sub_def =E<gt> ['code line 1;', 'code line 2;'] }>

Injects each element of the array ref as either a use statement, or in the
latter case, lines of code after a sub definition.

=head2 C<remove>

Parameters: C<delete =E<gt> 'string'>

Deletes the entire line of code, if it contains 'string'.


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


