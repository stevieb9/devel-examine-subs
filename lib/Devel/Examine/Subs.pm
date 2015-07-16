package Devel::Examine::Subs;

use strict;
use warnings;

our $VERSION = '1.18';

use Carp;
use Data::Dumper;
use Devel::Examine::Subs::Engine;
use Devel::Examine::Subs::Prefilter;
use PPI;
            
sub new {
    
    my $self = {};
    bless $self, shift;
    
    my $p = shift;

    if ($p->{file}){
        $self->_file($p);
    }

    $self->{namespace} = 'Devel::Examine::Subs';
    
    $self->{pre_filter} = $p->{pre_filter};
    $self->{engine} = $p->{engine};


    @{$self->{can_search}} = qw(has missing all has_lines);
    @{$self->{valid_params}} = qw(get file search lines);

    return $self;
}

sub run {
    my $self = shift;
    my $p = shift;

    $self->_config($p);
    $self->_core($p);
}

sub has {
    my $self    = shift;
    my $p       = shift;

    $p->{engine} = 'has';

    $self->_config($p);
    $self->run($p);
}

sub missing {
    my $self    = shift;
    my $p       = shift;

    $p->{engine} = 'missing';

    $self->_config($p);
    $self->run($p);
}
sub all {
    my $self    = shift;
    my $p       = shift;

    $p->{engine} = 'all';
    $self->_config($p); 
    $self->run($p);    
}
sub line_numbers {
    my $self = shift;
    my $p = shift;

    $self->{want} = 'line_numbers';
    $self->_config($p);

    if ($self->{get} and $self->{get} =~ /^obj/){
        $self->{want} = 'sublist';
        return $self->sublist();
    }
    else {
        return $self->_get();
    }
}
sub sublist {
    my $self = shift;
    my $p = shift;

    $self->{want} = 'sublist';
    $self->_config($p);

    $self->_get();

    return $self->{sublist};
}
sub module {
    my $self = shift;
    my $p = shift;

    $self->{want} = 'module';
    $self->_config($p);

    return @{$self->_get($p)};
}
sub _config {
    my $self = shift;
    my $p = shift;

    for my $param (keys %$p){

        if (grep(/$param/, @{$self->{valid_params}})){
    
            # validate the file

            if ($param eq 'file'){
                $self->_file($p); 
                next;
            }

            # validate search

            if (! exists $p->{search} or $p->{search} eq ''){
                $self->{bad_search} = 1; 
            }

            $self->{$param} = $p->{$param};
        }
    }
}
sub _file {
    my $self = shift;
    my $p = shift;

    $self->{file} = $p->{file} // $self->{file};

    if (! $self->{file} || ! -f $self->{file}){
        die "Invalid file supplied: $self->{file} $!";
    }
}
sub _get {
   
    my $self        = shift;
    my $p           = shift;

    my $file        = $self->{file};
    my $search      = $self->{search}; 
    my $want   = $self->{want};

    # do module() first, as we don't need to search in
    # any files

    # module

    if ($want eq 'module'){
        no strict 'refs';

        if (! $p->{module} or $p->{module} eq ''){
            return [];
        }

        (my $module_file = $p->{module}) =~ s|::|/|g;

        require "$module_file.pm"
          or die "Module $p->{module} not found: $!";

        my $namespace = "$p->{module}::";

        my @subs;

        for my $sub (keys %$namespace){
            if (defined &{$namespace . $sub}){
                push @subs, $sub;
            }
        }
   
        @subs = sort @subs; 
        
        return \@subs;
    }

    # fetch the sub data

    my $subs = $self->_core({
                        file => $file,
                        search => $search,
                        want => $want,
                    });


    # all
       
    return [ sort keys %$subs ] if $want eq 'all';

    # line_numbers

    if ($want eq 'line_numbers'){
        my @line_nums;

        for my $sub (keys %$subs){
            delete $subs->{$sub}{found};
        }
        return $subs;
    }

    # sublist

    if ($want eq 'sublist'){
        $self->_objects($subs);
        return $subs;
    }

    # has_lines ('lines' param to has())

    if ($want eq 'has_lines'){

        my %data;
        for my $sub (keys %$subs){
            if ($subs->{$sub}{lines}){
                $data{$sub} = $subs->{$sub}{lines};
            }
        }
        return \%data;
    }         
 
    # has & missing
     
    my (@has, @hasnt);

    for my $sub (keys %$subs){
        push @has,   $sub if $subs->{$sub}{found};
        push @hasnt, $sub if ! $subs->{$sub}{found};
    }

    return \@has if $want eq 'has';
    return \@hasnt if $want eq 'missing';
}

sub _core {
    use Tie::File;

    my $self = shift;
    my $p = shift;

    my $search = $self->{search};
    my $want = $self->{want};
    my $file = $self->{file};

    my $ppi_doc = PPI::Document->new($file);
    my $PPI_subs = $ppi_doc->find("PPI::Statement::Sub");
    tie my @fh, 'Tie::File', $file;

    # compile the file/sub data, return the base struct

    my $subs = $self->_load_subs();

    #    
    # perform the modular/callback work
    # 
    
    # run the data pre filter

    #my $pf = $self->_pre_filter($subs);
   
    # load the engine

    $subs = $self->_load_engine($p, $subs); 

    return $subs;
}

sub _load_subs {

    my $self = shift;
    
    my $file = $self->{file};

    my $ppi_doc = PPI::Document->new($file);
    my $PPI_subs = $ppi_doc->find("PPI::Statement::Sub");

    tie my @perl_file, 'Tie::File', $file;

    my %subs;
    $subs{$file} = {};
    $subs{$file}{TIE_perl_file} = \@perl_file;

    for my $PPI_sub (@{$PPI_subs}){
        
        my $name = $PPI_sub->name;
        
        $subs{$file}{subs}{$name}{start} = $PPI_sub->line_number;
        
        my $lines = $PPI_sub =~ y/\n//;

        $subs{$file}{subs}{$name}{stop} = $subs{$file}{subs}{$name}{start} + $lines;

        my $line_num = $subs{$file}{subs}{$name}{start};
       
        # pull out just the subroutine from the file array
        # and attach it to the structure

        my @sub_definition = @perl_file[
                                    $subs{$file}{subs}{$name}{start}
                                    ..
                                    $subs{$file}{subs}{$name}{stop}
                                   ];

          @{$subs{$file}{subs}{$name}{TIE_perl_file_sub}} = \@sub_definition;
    }

    return \%subs;
}

sub _load_engine {

    my $self = shift;
    my $p = shift;
    my $subs = shift;

    my $engine = $p->{engine} // $self->{engine};

    if (not ref($engine) eq 'CODE'){

        # engine is a name

        my $engine_module = $self->{namespace} . "::Engine";
        my $compiler = $engine_module->new();

        if (not $compiler->{engines}{$engine}){
            confess "No such engine: $engine";
        }

        $subs = $compiler->{engines}{$engine}->($p, $subs);
    }

    return $subs;
}

sub _pre_filter {

    my $self = shift;
    my $subs = shift;

    my $pre_filter_name = $self->{pre_filter};

    my $pre_filter;

    # default

    if (not $pre_filter_name or $pre_filter_name eq ''){
        return $subs;
    }

    # sent in

    if (not ref($pre_filter_name) eq 'CODE'){
        my $pre_filter_module = $self->{namespace} . "::Prefilter";
        my $compiler = $pre_filter_module->new();

        $subs = $compiler->{pre_filters}{$pre_filter_name}->($self, $subs);
    }

    return $subs;
}

sub _objects {

    use Devel::Examine::Subs::Sub;

    my $self = shift;
    my $subs = shift;

    my @sub_list;

    for my $sub (keys %$subs){
        my $obj = Devel::Examine::Subs::Sub->new($subs->{$sub}, $sub);
        push @sub_list, $obj;
    }

    $self->{sublist} = \@sub_list;
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
