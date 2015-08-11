package Devel::Examine::Subs; 
use warnings; 
use strict;

our $VERSION = '1.23';

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

    my @files;

    my $dir = $self->{params}{file};
    
    find({wanted => sub {
                        return if ! -f;
                       
                        my @extensions = @{$self->{params}{extensions}};
                        my $exts = join('|', @extensions);

                        if ($_ !~ /\.(?:$exts)$/i){
                            return;
                        }
                        
                        my $file = "$File::Find::name";

                        push @files, $file;
                      },
                        no_chdir => 1 }, $dir );

    my %struct;
    
    for my $file (@files){
        $self->{params}{file} = $file;
        my $data = $self->_core($self->{params});
        
        my $exists = 0;
        $exists = %$data if ref($data) eq 'HASH';
        $exists = @$data if ref($data) eq 'ARRAY';

        $struct{$file} = $data if $exists;
    }
    
    return \%struct;
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
        $self->{params}{extensions} = $p->{extensions} // [qw(pm pl)];
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

    # config
    
    $self->_config($p);
    $p = $self->{params};

    my $search = $self->{params}{search};
    my $file = $self->{params}{file};
    
    # pre processor

    my $data;

    if ($self->{params}{pre_proc}){
        my $pre_proc = $self->_pre_proc();

        $data = $pre_proc->($p);

        # for things that don't need to process files (such as 'module'), return early

        if ($self->{params}{pre_proc_return}){
            return $data;
        }
    }

    # processor

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

    # core dump

    if ($self->{params}{core_dump}){
        
        print "\n\t Core Dump called...\n\n";
        print "\n\n\t Dumping data... \n\n";
        print Dumper $subs;

        print "\n\n\t Dumping instance...\n\n";
        print Dumper $self;

        exit;
    }
    
    $self->{data} = $subs;
    return $subs;
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

        delete $self->{params}{include} if $exclude->[0];

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
       
        # pull out just the subroutine from the file array and attach it to the structure

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
   
    # tell _core() to return directly from the pre_processor if necessary, and bypass pre_filter and engine

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
                    $@ = "\n[Devel::Examine::Subs speaking] " .
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

        # engine has bad func val in dispatch table, but key is ok

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
    my $pre_proc = $module->new();

    my @pre_procs;

    for (keys %{$pre_proc->_dt()}){
        push @pre_procs, $_ if $_ !~ /^_/;
    }
    return @pre_procs;
}
sub pre_filters {

    my $self = shift;
    my $module = $self->{namespace} . "::Prefilter";
    my $pre_filter = $module->new();

    my @pre_filters;

    for (keys %{$pre_filter->_dt()}){
        push @pre_filters, $_ if $_ !~ /^_/;
    }
    return @pre_filters;
}
sub engines {

    my $self = shift;
    my $module = $self->{namespace} . "::Engine";
    my $engine = $module->new();
 
    my @engines;

    for (keys %{$engine->_dt()}){
        push @engines, $_ if $_ !~ /^_/;
    }
    return @engines;
}
sub has {

    my $self = shift;
    my $p = shift;

    $self->{params}{pre_filter} = 'file_lines_contain';
    $self->{params}{engine} = 'has';
    $self->_config($p);
    $self->run();
}
sub missing {

    my $self = shift;
    my $p = shift;

    $self->{params}{engine} = 'missing';
    $self->_config($p);
    $self->run();
}
sub all {

    my $self = shift;
    my $p = shift;

    $self->{params}{engine} = 'all';
    $self->_config($p);
    $self->run();
}
sub lines {

    my $self = shift;
    my $p = shift;
    
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

    # set the preprocessor up, and have it return before the building/compiling of file data happens

    $self->{params}{pre_proc} = 'module';
    $self->{params}{pre_proc_return} = 1;

    $self->{params}{engine} = 'module';

    $self->run();
}
sub objects {

    my $self = shift;
    my $p = shift;

    $self->_config($p);

    $self->{params}{pre_filter} = 'subs';
    $self->{params}{engine} = 'objects';

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

    $p->{injects} = 1 if ! $p->{injects};

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

sub _pod{} #vim placeholder 1; 
__END__

=head1 NAME

Devel::Examine::Subs - Get info, search/replace and inject code in Perl file subs.

=head1 SYNOPSIS

    use Devel::Examine::Subs;

    my $file = 'perl.pl'; # or directory name
    my $search = 'string';

    my $des = Devel::Examine::Subs->new({file => $file);

Get all sub names in a file

    my $aref = $des->all();

Print all subs within each Perl file under a directory

    my $files = $des->all({ file => 'lib/Devel/Examine' });

    for my $file (keys %$files){
        print "$file\n";
        print join('\t', @{$files->{$file}});
    }

Get all subs containing "string" in the body

    my $aref = $des->has({search => $search});

Search and replace code in subs

    $des->search_replace({
                    search => "$template = 'one.tmpl'",
                    replace => "$template = 'two.tmpl'",
                  });

Inject code into sub after a search term (preserves previous line's indenting)

    my @code = <DATA>;

    $des->inject_after({
                    search => 'this',
                    code => \@code,
                  });

    __DATA__

    # previously uncaught issue

    if ($foo eq "bar"){
        croak 'big bad error';
    }

Get all the subs as objects

    $aref = $des->objects(...)

    for my $sub (@$aref){
        $sub->name();       # name of sub
        $sub->start();      # number of first line in sub
        $sub->end();        # number of last line in sub
        $sub->num_lines();  # number of lines in sub
        $sub->code();       # entire sub code from file
        $sub->lines();      # see next example...

    }

Print out all lines in all subs that contain a search term

    my $lines_with_search_term = $sub->lines();

    for (@$lines_with_search_term){
        my ($line_num, $text) = split /:/, $_, 2;
        say "Line num: $line_num";
        say "Code: $text\n";
    }

The structures look a bit differently when 'file' is a directory. You need to add one more layer of extraction.

    my $files = $des->objects();

    for my $file (keys %$files){
        for my $sub (@{$files->{$file}}){
            ...
        }
    }





=head1 DESCRIPTION

Gather information about subroutines in Perl files (and in-memory modules), with the ability to search/replace code, inject new code, get line counts, get start and end line numbers, access the sub's code and a myriad of other options.






=head1 FEATURES

=over 4

=item - uses PPI for Perl file parsing

=item - search and replace code within subs, with the ability to include or exclude subs, something a global search/replace can't do (easily)

=item - inject new code into subs following a found search pattern

=item - retrieve all sub names where the sub does or doesn't contain a search term

=item - retrieve a list of sub objects for subs that match a search term, where each object contains a variety of information about itself, acessible via access methods

=item - include or exclude subs to be processed

=item - differentiates a directory from a file, and acts accordingly by recursing and processing specified files

=item - extremely modular and extensible; the core of the system uses plugin-type callbacks for everything

=item - pre-defined callbacks are used by default, but user-supplied ones are loaded dynamically

=back






=head1 METHODS

=head2 C<new({ file =E<gt> $filename })>

Instantiates a new object.

Takes the name of a file to search. If $filename is a directory, it will be searched recursively for files. You can set any 
and all parameters this module uses in any method, however, only the 'file', 'extensions' and 'regex' params are guaranteed to stay persistent, so best to supply your desired params to each call. 

See the L<PARAMETERS> section for optional parameters that can and perhaps should be set here. 




=head2 C<all()>

Returns an array reference containing the names of all subroutines found in the file.






=head2 C<has({ search =E<gt> $text })>

Returns an array reference containing the names of the subs where the subroutine contains the text.




=head2 C<missing({ search =E<gt> $text })>

The exact opposite of has.








=head2 C<module({ module =E<gt> 'Devel::Examine::Subs' } )>

Returns an array reference containing the names of all subs found in the module's namespace symbol table.




=head2 C<lines({ search =E<gt> $text })>

Gathers together all line text and line number of all subs where the sub contains lines matching the search term.

Returns a hash reference with the sub name as the key, the value being an array reference which contains a hash reference in the format line_number =E<gt> line_text.




=head2 C<search_replace({ search =E<gt> 'this', replace =E<gt> 'that', copy =E<gt> 'file.ext' })>

Search for lines that contain certain text, and replace the search term with the replace term. If the optional parameter 'copy' is sent in, a copy of the original file will be created in the current directory with the name specified, and that file will be worked on instead. Good for testing to ensure The Right Thing will happen in a production file.

This method will create a backup copy of the file with the same name appended with '.bak', but don't confuse this feature with the 'copy' parameter.






=head2 C<inject_after({ search =E<gt> 'this', code =E<gt> \@code })>

Injects the code in C<@code> into the sub within the file, where the sub contains the search term. The same indentation level of the 
line that contains the search term is used for any new code injected. Set C<no_indent> parameter to a true value to disable this 
feature.

By default, an injection only happens after the first time a search term is found. Use the C<injects> parameter (see L<PARAMETERS>) to change this behaviour. Setting to a positive integer beyond 1 will inject after that many finds. Set to a negative integer will inject after all finds.

The C<code> array should contain one line of code (or blank line) per each element. (See L<SYNOPSIS> for an example).



Optional parameters:

=over 4



=item C<copy>

See C<search_replace()> for a description of how this parameter is used.

=back



=head2 C<pre_procs()>

Returns a list of all available pre processor modules.



=head2 C<pre_filters()>

Returns a list of all available built-in pre engine filter modules.



=head2 C<engines()>

Returns a list of all available built-in 'engine' modules.


=head2 C<run()>

All public methods call this method internally. The public methods set certain variables (filters, engines etc). You can get the same 
effect programatically by using C<run()>. Here's an example that performs the same operation as the C<has()> public method:

    my $params = {
            search => 'text',
            pre_filter => 'file_lines_contain',
            engine => 'has',
    };

    my $return = $des->run($params);

This allows for very fine-grained interaction with the application, and makes it easy to write new engines and for testing.


=head2 C<add_functionality()>

WARNING!: This method is highly experimental and is used for developing internal processors only. Only 'engine' is functional, and only 
half way. It's simply a proof-of-concept of the 'Processor' structure which I will be incorporating into a new module template system 
that allows people to replicate the base structure of this module (less the data and processors). DO NOT USE.

While writing new processors, set the processor type to a callback within the local working file. When the code performs the actions you 
want it to, put a comment line before the code with C<#<des>> and a line following the code with C<#</des>>. DES will slurp in all of 
that code live-time, inject it into the specified processor, and configure it for use. See C<examples/write_new_engine.pl> for an 
example of creating a new 'engine' processor.




Parameters:

=over 4

=item C<add_functionality>

Informs the system which type of processor to inject and configure. Permitted values are 'pre_proc', 'pre_filter' and 'engine'.

=item C<add_functionality_prod>

Set to a true value, will update the code in the actual installed Perl module file, instead of a local copy.

=back





Optional parameters:

=over 4

=item C<copy> 

Set it to a new file name which will copy the original, and only change the copy. Useful for verifying the changes took 
properly.

=back







=head1 PARAMETERS

There are various optional global parameters that can be used. These should be set in C<new()>, unless you want them only briefly in which case just call them within the user public methods.

=over 4

=item C<file>

The name of a file, or a directory. If set in C<new>, you can omit it from all subsequent method calls until you want it changed. Once changed in a call, the updated value will remain persistent until changed again.


=item C<diff>

Not yet implemented. 

Compiles a diff after each edit using the methods that edit files.




=item C<include>

An array reference containing the names of subs to include. This (and C<exclude>) tell the Processor phase to generate only these subs, significantly reducing the work that needs to be done in subsequent method calls.



=item C<exclude>

An array reference of the names of subs to exclude. See C<include> for further details.

Note that C<exclude> renders C<include> useless.



=item C<no_indent>

In the processes that write new code to files, the indentation level of the line the search term was found on is used for inserting the 
new code by default. Set this parameter to a true value to disable this feature and set the new code at the beginning column of the 
file.

=item C<injects>

Informs C<inject_after()> how many injections to perform. For instance, if a search term is found five times in a sub, how many of those do you want to inject the code after?

Default is 1. Set to a higher value to achieve more injects. Set to a negative integer to inject after all.

=item C<regex>

Set to a true value, all values in the 'search' parameter become regexes. For example with regex on, C</thi?s/> will match "this", but without regex, it won't. This parameter is persistent; it remains until reset manually.

=item C<extensions>

By default, we load only C<*.pm> and C<*.pl> files. Use this parameter to load different files. Only useful when a directory is passed in as opposed to a file. This parameter is persistent until manually reset and should be set in C<new>.

Values: Array reference where each element is the name of the extension (less the dot). For example, C<['pm', 'pl']> is the default.


=item C<pre_proc_dump>, C<pre_filter_dump>, C<engine_dump>, C<core_dump>

Set to 1 to activate, C<exit()>s after completion.

Print to STDOUT using Data::Dumper the structure of the data following the respective phase. The C<core_dump> will print the state of 
the data, as well as the current state of the entire DES object.

NOTE: The 'pre_filter' phase is run in such a way that pre-filters can be daisy-chained. Due to this reason, the value of 
C<pre_filter_dump> works a little differently. For example:

    pre_filter => 'one && two';

...will execute filter 'one' first, then filter 'two' with the data that came out of filter 'one'. Simply set the value to the number 
that coincides with the location of the filter. For instance, C<pre_filter_dump =E<gt> 2;> will dump the output from the second filter and 
likewise, C<1> will dump after the first.



=item C<pre_proc_return>, C<pre_filter_return>, C<engine_return>

Returns the structure of data immediately after being processed by the respective phase. Useful for writing new 'phases'. (See "SEE 
ALSO" for details).

NOTE: C<pre_filter_return> does not behave like C<pre_filter_dump>. It will only return after all pre-filters have executed.



=item C<clean_config>

Resets all configuration variables back to C<undef>, less the persistent global ones ('file', 'extensions', 'regex').



=item C<config_dump>

Prints to STDOUT with Data::Dumper the current state of all loaded configuration parameters.




=back








=head1 SEE ALSO

=over 4

=item C<perldoc Devel::Examine::Subs::Preprocessor>

Information related to the 'pre_proc' phase core modules.

=item C<perldoc Devel::Examine::Subs::Prefilter>

Information related to the 'pre_filter' phase core modules.

=item C<perldoc Devel::Examine::Subs::Engine>

Information related to the 'engine' phase core modules.

=back







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
