package Devel::Examine::Subs::Preprocessor;

use strict; use warnings;

use Carp;
use Data::Dumper;
use Devel::Trace::Flow qw(trace);

our $VERSION = '1.29';

sub new {
	trace();


    my $self = {};
    bless $self, shift;

    my $struct = shift;

    $self->{pre_procs} = $self->_dt;

    return $self;
}

sub _dt {
	trace();


    my $self = shift;

    my $dt = {
        module => \&module,
        _test_bad => \&test_bad,
    };

    return $dt;
}

sub exists {
	trace();

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
	trace();


    return sub {

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
1;
sub _vim_placeholder {}
	trace();

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

Mandatory parameters: C<{ module => 'Module::Name' }>

This pre-processor returns an array reference of all subroutines within the
namespace of the module listed in the C<module> parameter.

The data is returned early as mentioned in the L<DESCRIPTION>.

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


