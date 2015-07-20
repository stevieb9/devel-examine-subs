package Devel::Examine::Subs;

use strict;
use warnings;

our $VERSION = '1.18';

use Carp;
use Data::Dumper;
use Devel::Examine::Subs::Engine;
use Devel::Examine::Subs::Preprocessor;
use Devel::Examine::Subs::Prefilter;
use PPI;
use Tie::File;

sub new {
    
    my $self = {};
    bless $self, shift;
    
    my $p = shift;

    $self->{namespace} = 'Devel::Examine::Subs';
    
    $self->_config($p);

    return $self;
}
sub run {

    my $self = shift;
    my $p = shift;

    $self->_config($p);
    
    $self->_core($self->{params});
}
sub _config {

    my $self = shift;
    my $p = shift;

    for my $param (keys %$p){

        # validate the file

        if ($param eq 'file'){
            $self->_file($p); 
            next;
        }

        # validate search

        if (! exists $p->{search} or $p->{search} eq ''){
            $self->{params}{bad_search} = 1; 
        }

        $self->{params}{$param} = $p->{$param};

    }

    if ($self->{params}{config_dump}){
        print Dumper $self->{params};
    }
}
sub _file {

    my $self = shift;
    my $p = shift;

    $self->{params}{file} = $p->{file} // $self->{params}{file};

    if (! $self->{params}{file} || ! -f $self->{params}{file}){
        die "Invalid file supplied: $self->{params}{file} $!";
    }
}
sub _core {
    
    my $self = shift;
    my $p = shift;

    # process the incoming params, then rebuild $p
    
    $self->_config($p);
    $p = $self->{params};

    my $search = $self->{params}{search};
    my $file = $self->{params}{file};

    # pre data collection/building processor

    my $data;

    if ($self->{params}{pre_proc}){
        my $pre_proc = $self->_pre_proc();

        $data = $pre_proc->($p);

        # for things like 'module', we need to return
        # early

        if ($self->{params}{pre_proc_return}){
            return $data;
        }
    }

    # core data collection/building

    my $subs = $self->_subs();
    
    $self->{data} = $subs;

    # pre engine filter

    if ($self->{params}{pre_filter}){

        $self->{params}{pre_filter} =~ s/\s+//g;
        my @pre_filter_list = split /&&/, $self->{params}{pre_filter};
    
        for my $pf (@pre_filter_list){
            $self->{params}{pre_filter} = $pf;

            my $pre_filter = $self->_pre_filter();

            $subs = $pre_filter->($p, $subs); 

            $self->{data} = $subs;

        }

        if ($self->{params}{pre_filter_return}){
            return $subs;
        }
    }

    # engine

    my $engine = $self->_engine($p);

    if ($self->{params}{engine}){
        $subs = $engine->($p, $subs);
    }

    if ($self->{params}{core_dump}){
        
        print "\n\t Core Dump called...\n\n";
        print "\n\n\t Dumping data... \n\n";
        print Dumper $subs;

        print "\n\n\t Dumping instance...\n\n";
        print Dumper $self;

        exit;
    }
    return $subs;

    $self->{data} = $subs;
}
sub _subs {

    my $self = shift;
    
    my $file = $self->{params}{file};

    my $ppi_doc = PPI::Document->new($file);
    my $PPI_subs = $ppi_doc->find("PPI::Statement::Sub");

    tie my @perl_file, 'Tie::File', $file;

    my %subs;
    $subs{$file} = {};
    $subs{$file}{TIE_perl_file} = \@perl_file;

    for my $PPI_sub (@{$PPI_subs}){
        
        my $name = $PPI_sub->name;
        
        $subs{$file}{subs}{$name}{start} = $PPI_sub->line_number;
        $subs{$file}{subs}{$name}{start}--;
        
        my $lines = $PPI_sub =~ y/\n//;

        $subs{$file}{subs}{$name}{end} = $subs{$file}{subs}{$name}{start} + $lines;

        my $line_num = $subs{$file}{subs}{$name}{start};
       
        # pull out just the subroutine from the file array
        # and attach it to the structure

        my @sub_definition = @perl_file[
                                    $subs{$file}{subs}{$name}{start}
                                    ..
                                    $subs{$file}{subs}{$name}{end}
                                   ];

          $subs{$file}{subs}{$name}{TIE_perl_file_sub} = \@sub_definition;
    }
   
    untie @perl_file;

    return \%subs;
}
sub _engine {

    my $self = shift;
    my $p = shift;
    my $struct = shift;

    $self->_config($p);

    my $engine = $p->{engine} // $self->{params}{engine};

    if (not $engine or $engine eq ''){
        return $struct;
    }

    my $cref;

    if (not ref($engine) eq 'CODE'){

        # engine is a name

        my $engine_module = $self->{namespace} . "::Engine";
        my $compiler = $engine_module->new();

        if (not $compiler->{engines}{$engine}){
            confess "No such engine: >>>$engine<<<";
        }

        eval {
            $cref = $compiler->{engines}{$engine}->();
        };
        
        if ($@){
            print "\n[Devel::Examine::Subs speaking] " .
                  "dispatch table in Devel::Examine::Subs::Engine " .
                  "has a mistyped function value:\n\n";
            confess $@;
        }
    }

    if (ref($engine) eq 'CODE'){
        $cref = $engine;
    }

    if ($self->{params}{engine_dump}){
        my $subs = $cref->($p, $self->{data});
        print Dumper $subs;
        exit;
    }

    return $cref;
}
sub _pre_filter {

    my $self = shift;
    my $p = shift; 
    my $struct = shift;

    $self->_config($p);

    my $pre_filter = $self->{params}{pre_filter};
    my $pre_filter_dump = $self->{params}{pre_filter_dump};

    if (not $pre_filter or $pre_filter eq ''){
        return $struct;
    }
    
    my $cref;

    if (not ref($pre_filter) eq 'CODE'){
        my $pre_filter_module = $self->{namespace} . "::Prefilter";
        my $compiler = $pre_filter_module->new();

        $cref = $compiler->{pre_filters}{$pre_filter}->();
    }
    
    if (ref($pre_filter) eq 'CODE'){
        $cref = $pre_filter;
    }
    
    if ($pre_filter_dump && $pre_filter_dump > 1){
        $self->{params}{pre_filter_dump}--;
        $pre_filter_dump = $self->{params}{pre_filter_dump};
    }


    if ($pre_filter_dump && $pre_filter_dump == 1){
        my $subs = $cref->($p, $self->{data});
        print Dumper $subs;
        exit;
    }

    return $cref;
}
sub pre_filters {

    my $self = shift;
    my $module = $self->{namespace} . "::Prefilter";
    my $pre_filter = $module->new();

    return keys (%{$pre_filter->_dt()});
}
sub pre_procs {

    my $self = shift;
    my $module = $self->{namespace} . "::Preprocessor";
    my $pre_procs = $module->new();

    return keys (%{$pre_procs->_dt()});
}
sub engines {

    my $self = shift;
    my $module = $self->{namespace} . "::Engine";
    my $engine = $module->new();

    return keys (%{$engine->_dt()});
}
sub _pre_proc {

    my $self = shift;
    my $p = shift;
    my $subs = shift;

    $self->_config($p);

    my $pre_proc = $self->{params}{pre_proc};

    if (not $pre_proc or $pre_proc eq ''){
        return $subs;
    }
   
    # tell _core() to return directly from the pre_processor
    # if necessary, and bypass pre_filter and engine

    if ($pre_proc eq 'module'){
       $self->{params}{pre_proc_return} = 1;
    }

    my $cref;
    
    if (not ref($pre_proc) eq 'CODE'){
        my $pre_proc_module = $self->{namespace} . "::Preprocessor";
        my $compiler = $pre_proc_module->new();

        $cref = $compiler->{pre_procs}{$pre_proc}->();
    }

    if (ref($pre_proc) eq 'CODE'){
        $cref = $pre_proc;
    }
    
    if ($self->{params}{pre_proc_dump}){
        my $data = $cref->($p);
        print Dumper $data;
        exit;
    }

    return $cref;
}
sub has {

    my $self    = shift;
    my $p       = shift;

    $self->_config($p);
    $self->{params}{engine} = 'has';
    $self->run();
}
sub missing {

    my $self    = shift;
    my $p       = shift;

    $self->_config($p);
    $self->{params}{engine} = 'missing';
    $self->run();
}
sub all {

    my $self    = shift;
    my $p       = shift;

    $self->_config($p); 
    $self->{params}{engine} = 'all';
    $self->run();    
}
sub lines {

    my $self    = shift;
    my $p       = shift;
    
    $self->_config($p); 
    
    $self->{params}{engine} = 'lines'; 
    
    if ($self->{params}{search}){
        $self->{params}{pre_filter} = 'file_lines_contain'; 
    }

    $self->run();
}
sub module {

    my $self = shift;
    my $p = shift;

    $self->_config($p);

    # set the preprocessor up, and have it return before
    # the building/compiling of file data happens

    $self->{params}{pre_proc} = 'module';
    $self->{params}{pre_proc_return} = 1;

    $self->{params}{engine} = 'module';

    $self->run();
}
sub objects {

    my $self = shift;
    my $p = shift;

    $self->_config($p);

    $self->{params}{pre_filter} = 'subs && objects';
    $self->{params}{pre_filter_return} = 1;
 
    $self->run();
}
sub search_replace {

    my $self = shift;
    my $p = shift;

    $self->_config($p);

    $self->{params}{pre_filter} 
      = 'file_lines_contain && subs && objects';

    $self->{params}{engine} = 'search_replace';

    $self->run();
}
sub inject_after {

    my $self = shift;
    my $p = shift;

    $self->_config($p);

    $self->{params}{pre_filter} 
      = 'file_lines_contain && subs && objects';

    $self->{params}{engine} = 'inject_after';

    $self->run();
}

sub _pod{} #vim placeholder
1;
__END__

=head1 NAME

Devel::Examine::Subs - Get information about subroutines within module and program files, and in-memory modules.

=head1 SYNOPSIS

    use Devel::Examine::Subs;

    my $des = Devel::Examine::Subs->new();

    my $file = 'perl.pl';
    my $find = 'string';

    # get all sub names in file

    my @subs = $des->all({file => $file}); 

    # all subs containing "string" in the body

    my @has = $des->has({file => $file, search => $find}); 

    # return an aref of subroutine objects

    $aref = $des->sublist(...)

    for my $sub (@$aref){    
        print $sub->name() # name of sub
        print $sub->start() # first line of sub
        print $sub->stop() # last line of sub
        print $sub->count() # number of lines in sub
    }

    # see the has() method below to find out how to
    # get a return that contains all lines that match the search
    # for each sub

=head1 DESCRIPTION

NOTE: This module now requires the PPI module to be installed.

Reads into Perl program and module files (or modules in memory) 
returning the names of its subroutines, optionally limiting 
the names returned to subs that contain or do not contain 
specified text, or the start and end line numbers of the sub.

This module is much safer and accurate than earlier versions, as
it now uses the reliable PPI module to parse the perl code.

=head1 METHODS

=head2 new

Instantiates a new object. 

=head2 has({file => $filename, search => $text, lines => 1})

Takes the name of a file to search, and the text you want to
search for within each sub. Useful to find out which subs call
other methods.

By default, returns a list of names of the subs where the subroutine containes
the text. In scalar context, returns the count of subs containing
the found text. 

With the 'lines' parameter set to true, returns
a hash which each sub name is the key, and each key containing an
array containing hashes who's keys are the line numer the search found,
and the value is the data on that line.

=head2 missing({file => $filename, search => $text})

The exact opposite of has.

=head2 all({file => $filename})

Returns a list of the names of all subroutines found in the file.

=head2 module({module => "Devel::Examine::Subs"})

Returns an array containing a list of all subs found in the module's 
namespace symbol table.

=head2 line_numbers({file => $filename, get => 'object'})

If the optional parameter 'get' is not present or set to a
value of 'object' or 'obj', returns a hash of hashes. 
Top level keys are the function names, and the subkeys 'start' 
and 'stop' contain the line numbers of the respective position 
in the file for the subroutine.

If the optional parameter 'get' is sent in with a value of object,
will return an array reference of subroutine objects. Each object
has the following methods:

=head3 name()

Returns the name of the subroutine

=head3 start()

Returns the line number where the sub starts

=head3 stop()

Returns the line number where the sub ends

=head3 count()

Returns the number of lines in the subroutine

=head2 sublist({file => $filename})

Returns an array reference of subroutine objects. See line_numbers()
with the 'get' parameter set for details.

=head1 CAVEATS

The previous unreliability caveat has been removed as PPI now
performs all of the perl file processing.

The previous caveats were:

Subs that begin indented (such as closures and those within other
blocks) will not be counted. For line_numbers() the closing brace
must be in column one of the file as well.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Examine::Subs

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
