package Devel::Examine::Subs;

use strict;
use warnings;

our $VERSION = '1.18';

use Carp;
use Data::Dumper;
use Devel::Examine::Subs::Engine;
use Devel::Examine::Subs::Preprocessor;
use Devel::Examine::Subs::Prefilter;
use File::Find;
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

    # do something different for a dir 

    if ($self->{params}{directory}){
        my $files = $self->run_directory();
    }
    else {
        $self->_core($self->{params});
    }
}
sub run_directory {

    my $self = shift;
    my $p = shift;

    $self->_config($p);
   
    my $dir = $self->{params}{file};
    
    my @files;

    find({wanted => sub {
                        my $ext = $self->{params}{extension};
                        if (! -f or ! /(?:$ext)$/){ return; }
                        my $file = "$File::Find::name";
                        push @files, $file;
                      },
                        no_chdir => 1 }, $dir );

    my %return;

    for my $file (@files){
        $self->{params}{file} = $file;
        my $data = $self->_core($self->{params});
        
        my $exists = 0;
        $exists = %$data if ref($data) eq 'HASH';
        $exists = @$data if ref($data) eq 'ARRAY';

        $return{$file} = $data if $exists;
    }
    return \%return;
}
sub _config {

    my $self = shift;
    my $p = shift;

    if ($p->{clean_config}){
        delete $self->{params};
        return;
    }

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

    # configure directory searching for run()

    if (-d $self->{params}{file}){
        $self->{params}{directory} = 1;
        $self->{params}{extension} = $p->{extention} // '\.pm|\.pl';
    }
    else {
        if (! $self->{params}{file} || ! -f $self->{params}{file}){
            die "Invalid file supplied: $self->{params}{file} $!";
        }
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
    
    $subs = $subs // 0;
    return if ! $subs;

    $self->{data} = $subs;

    # pre engine filter

    if ($self->{params}{pre_filter}){
        for my $pre_filter ($self->_pre_filter()){
            $subs = $pre_filter->($p, $subs);
            $self->{data} = $subs;
        }
    }  

    if ($self->{params}{pre_filter_return}){
        return $subs;
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

    return {} if ! $file;

    my $ppi_doc = PPI::Document->new($file);
    my $PPI_subs = $ppi_doc->find("PPI::Statement::Sub");

    return if ! $PPI_subs;

    tie my @TIE_file, 'Tie::File', $file;

    my %subs;
    $subs{$file} = {};
    
    @{$subs{$file}{TIE_file}} = @TIE_file;

    for my $PPI_sub (@{$PPI_subs}){

        my $include = $self->{params}{include} // [];
        my $exclude = $self->{params}{exclude} // [];

        my $name = $PPI_sub->name;

        # bug 48: bail out if caller wants specific subs only

        next if grep {$name eq $_ } @$exclude;

        if ($include->[0]){
            next if (! grep {$name eq $_ && $_} @$include);
        }

        $subs{$file}{subs}{$name}{start} = $PPI_sub->line_number;
        $subs{$file}{subs}{$name}{start}--;
        
        my $lines = $PPI_sub =~ y/\n//;

        $subs{$file}{subs}{$name}{end} = $subs{$file}{subs}{$name}{start} + $lines;

        my $count_start = $subs{$file}{subs}{$name}{start};
        $count_start--;

        my $sub_line_count 
          = $subs{$file}{subs}{$name}{end} - $count_start;

        $subs{$file}{subs}{$name}{num_lines} = $sub_line_count;

        my $line_num = $subs{$file}{subs}{$name}{start};
       
        # pull out just the subroutine from the file array
        # and attach it to the structure

        my @sub_definition = @TIE_file[
                                    $subs{$file}{subs}{$name}{start}
                                    ..
                                    $subs{$file}{subs}{$name}{end}
                                   ];

          $subs{$file}{subs}{$name}{TIE_file_sub} = \@sub_definition;
    }
   
    untie @TIE_file;

    return \%subs;
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

        if (! $compiler->exists($pre_proc)){
            croak "pre_processor '$pre_proc' is not implemented.\n";
        }

        eval {
            $cref = $compiler->{pre_procs}{$pre_proc}->();
        };
        
        if ($@){
            $@ = "\n[Devel::Examine::Subs speaking] " .
                  "dispatch table in Devel::Examine::Subs::Preprocessor " .
                  "has a mistyped function as a value, but the key is ok\n\n"
            . $@;
            croak $@;
        }

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
sub _pre_filter {

    my $self = shift;
    my $p = shift; 
    my $struct = shift;

    $self->_config($p);

    my $pre_filter = $self->{params}{pre_filter};
    my $pre_filter_dump = $self->{params}{pre_filter_dump};

    my @pre_filters;

    if ($pre_filter){

        # prefilter contains an array ref of crefs

        if (ref($pre_filter) eq 'ARRAY'){
            push @pre_filters, $_ for @$pre_filter;
            return @pre_filters;
        }
 
        $self->{params}{pre_filter} =~ s/\s+//g;

        my @pre_filter_list;

        if ($self->{params}{pre_filter} =~ /&&/){
            @pre_filter_list = split /&&/, $self->{params}{pre_filter};
        }
        else {
            push @pre_filter_list, $pre_filter;
        }
                
        for my $pf (@pre_filter_list){
 
            if (ref($pre_filter) && ref($pre_filter) ne 'CODE' && $pre_filter eq ''){
                push @pre_filters, sub { my ($p, $struct); return $struct };
                return @pre_filters;
            }
    
            my $cref;

            if (not ref($pf) eq 'CODE'){
                my $pre_filter_module = $self->{namespace} . "::Prefilter";
                my $compiler = $pre_filter_module->new();

                # pre_filter isn't in the dispatch table

                if (! $compiler->exists($pf)){
                    croak "pre_filter '$pf' is not implemented. '$pre_filter' was sent in.\n";
                }
                
                eval {
                    $cref = $compiler->{pre_filters}{$pf}->();
                };
        
                if ($@){
                    $@ =  "\n[Devel::Examine::Subs speaking] " .
                          "dispatch table in Devel::Examine::Subs::Prefilter " .
                          "has a mistyped function as a value, but the key is ok\n\n"
                    . $@;
                    croak $@;
                }
            } 
            if (ref($pf) eq 'CODE'){
                $cref = $pf;
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
    
            push @pre_filters, $cref;
        }
    }
    else {
        return;
    }
    return @pre_filters;
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

        # engine isn't in the dispatch table

        if (! $compiler->exists($engine)){
            croak "engine '$engine' is not implemented.\n";
        }

        eval {
            $cref = $compiler->{engines}{$engine}->();
        };

        # engine has bad func val in dispatch table,
        # but key is ok

        if ($@){
            $@ = "\n[Devel::Examine::Subs speaking] " .
                  "dispatch table in Devel::Examine::Subs::Engine " .
                  "has a mistyped function as a value, but the key is ok\n\n"
            . $@;
            croak $@;
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
sub pre_procs {

    my $self = shift;
    my $module = $self->{namespace} . "::Preprocessor";
    my $pre_procs = $module->new();

    return keys (%{$pre_procs->_dt()});
}
sub pre_filters {

    my $self = shift;
    my $module = $self->{namespace} . "::Prefilter";
    my $pre_filter = $module->new();

    return keys (%{$pre_filter->_dt()});
}
sub engines {

    my $self = shift;
    my $module = $self->{namespace} . "::Engine";
    my $engine = $module->new();

    return keys (%{$engine->_dt()});
}
sub has {

    my $self    = shift;
    my $p       = shift;

    $self->{params}{pre_filter} = 'file_lines_contain';
    $self->{params}{engine} = 'has';
    $self->_config($p);
    $self->run();
}
sub missing {

    my $self    = shift;
    my $p       = shift;

    $self->{params}{engine} = 'missing';
    $self->_config($p);
    $self->run();
}
sub all {

    my $self    = shift;
    my $p       = shift;

    $self->{params}{engine} = 'all';
    $self->_config($p); 
    $self->run();    
}
sub lines {

    my $self    = shift;
    my $p       = shift;
    
    $self->{params}{engine} = 'lines'; 
    $self->_config($p); 
    
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
    $self->{params}{pre_filter_return} = 2;
 
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
sub add_functionality {
    
    my $self = shift;
    my $p = shift;

    $self->_config($p);
    
    my $to_add = $self->{params}{add_functionality};
    print "$to_add\n";
    my $in_prod = $self->{params}{add_functionality_prod};

    my @allowed = qw(
                    pre_proc 
                    pre_filter 
                    engine
    );


    if (! (grep {$to_add eq $_} @allowed)){
        croak "Adding a non-allowed piece of functionality...\n";
    }

    my %dt = (
            engine => sub { 
                        return $in_prod 
                        ? $INC{'Devel/Examine/Subs/Engine.pm'} 
                        : 'lib/Devel/Examine/Subs/Engine.pm'; 
                      },
    );

    my $caller = (caller())[1];

    open my $fh, '<', $caller
      or confess "can't open the caller file $caller: $!";

    my $code_found = 0;
    my @code;

    while (<$fh>){
        chomp;
        if (m|^#(.*)<des>|){
            $code_found = 1;
            next;
        }
        next if ! $code_found;
        last if m|^#(.*)</des>|;
        push @code, $_;
    }

    my $file = $dt{$to_add}->();

    my $des = Devel::Examine::Subs->new({
                                    file => $file,
                                    pre_filter => 'end_of_last_sub',
                                });

    
    tie my @TIE_file, 'Tie::File', $file
      or croak "can't Tie::File the file $file: $!";

    my $end_line = $des->run();

    push @TIE_file, @code;    
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
