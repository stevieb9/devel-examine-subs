package Devel::Examine::Subs;
use warnings;
use strict;

our $VERSION = '1.28';

use Carp;
use Data::Compare;
use Data::Dumper;
use Devel::Examine::Subs::Engine;
use Devel::Examine::Subs::Preprocessor;
use Devel::Examine::Subs::Prefilter;
use File::Find;
use PPI;
use Symbol;
use Tie::File;

sub new {

    my $self = {};
    bless $self, shift;

    my $p = $self->_params(@_);

    # default configs

    $self->{namespace} = 'Devel::Examine::Subs';
    $self->{params}{regex} = 1;

    $self->_config($p);

    return $self;
}
sub run {

    my $self = shift;
    my $p = shift;

    $self->_config($p);

    $self->_run_end(0);

    my $struct;

    if ($self->{params}{directory}){
        $struct = $self->_run_directory;
    }
    else {
        $struct = $self->_core($p);
    }

    $self->_run_end(1);
    $self->_clean_core_config;

    return $struct;
}
sub _run_directory {

    my $self = shift;
    my $p = shift;

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
                        no_chdir => 1
                    }, $dir );

    my %struct;

    for my $file (@files){
        $self->{params}{file} = $file;
        my $data = $self->_core($p);

        my $exists = 0;
        $exists = %$data if ref($data) eq 'HASH';
        $exists = @$data if ref($data) eq 'ARRAY';

        $struct{$file} = $data if $exists;
    }

    return \%struct;
}
sub _run_end {
    my $self = shift;
    my $value = shift;

    $self->{run_end} = $value if defined $value;

    return $self->{run_end};
}
sub _cache {
    my $self = shift;
    my $file = shift if @_;
    my $struct = shift if @_;

    if ($self->{params}{cache_dump}){

        print Dumper $self->{cache};

        if ($self->{params}{cache_dump} > 1){
            exit;
        }
    }

    if (! $struct && $file){
        return $self->{cache}{$file};
    }
    if ($file && $struct){
        $self->{cache}{$file} = $struct;
    }
}
sub _cache_enabled {
    my $self = shift;
    return $self->{params}{cache};
}
sub _cache_safe {
    my $self = shift;
    my $value = shift;

    $self->{cache_safe} = $value if defined $value;

    return $self->{cache_safe};
}
sub _params {
    my $self = shift;
    my %params = @_;
    return \%params;
}
sub _config {

    my $self = shift;
    my $p = shift;

    my %valid_params = (

        # persistent

        file => 1,
        extensions => 1,
        regex => 1,
        copy => 1,
        diff => 1,
        no_indent => 1,
        cache => 1,

        # persistent - core phases

        pre_proc => 1,
        pre_filter => 1,
        engine => 1,

        # transient

        directory => 0,
        search => 0,
        replace => 0,
        injects => 0,
        code => 0,
        include => 0,
        exclude => 0,
        lines => 0,
        module => 0,
        objects_in_hash => 0,
        pre_proc_dump => 0,
        pre_filter_dump => 0,
        engine_dump => 0,
        core_dump => 0,
        pre_proc_return => 0,
        pre_filter_return => 0,
        engine_return => 0,
        config_dump => 0,
        cache_dump => 0,
    );

    $self->{valid_params} = \%valid_params;

    # get previous run's config

    %{$self->{previous_run_config}} = %{$self->{params}};

    # clean config

    $self->_clean_config(\%valid_params, $p);

    for my $param (keys %$p){

        # validate the file

        if ($param eq 'file'){
            $self->_file($p);
            next;
        }

        $self->{params}{$param} = $p->{$param};
    }

    # check if we can cache

    if ($self->_cache_enabled) {

        my @unsafe_cache_params
            = qw(file extensions include exclude search);

        my $current = $self->{params};
        my $previous = $self->{previous_run_config};

        for (@unsafe_cache_params) {
            my $safe = Compare($current->{$_}, $previous->{$_}) || 0;

            $self->_cache_safe($safe);

            last if !$self->_cache_safe;
        }
    }

    if ($self->{params}{config_dump}){
        print Dumper $self->{params};
    }
}
sub _clean_config {
    my $self = shift;
    my $config_vars = shift; # href of valid params
    my $p = shift; # href of params passed in

    for my $var (keys %$config_vars){
       
        last if ! $self->_run_end;

        # skip if it's a persistent var

        next if $config_vars->{$var} == 1;

        delete $self->{params}{$var};
    }

    # delete non-valid params

    for my $param (keys %$p){
        if (! exists $config_vars->{$param}){
            #warn "\n\nDES::_clean_config() deleting invalid param: $param\n";
            delete $p->{$param};
        }
    }
}
sub _clean_core_config {
    # deletes core phase info after each run

    my $self = shift;

    my @core_phases = qw( 
        pre_proc
        pre_filter
        engine
    );

    for (@core_phases){
        delete $self->{params}{$_};
    }
}
sub _file {

    my $self = shift;
    my $p = shift;

    $self->{params}{file} = $p->{file} // $self->{params}{file};

    # if a module was passed in, dig up the file

    if ($self->{params}{file} =~ /::/){

        my $module = $self->{params}{file};
        (my $file = $module) =~ s|::|/|g;
        $file .= '.pm';
       
        my $module_is_loaded;
        
        if (! $INC{$file}){
            eval { require $module; };

            if ($@){
                $@ = "Devel::Examine::Subs::_file() speaking ... " .
                     "Can't transform module to a file name\n\n"
                     . $@;
                croak $@;
            }
        }
        else {
            $module_is_loaded = 1;
        }

        # set the file param

        $self->{params}{file} = $INC{$file};

        if (! $module_is_loaded){
            delete_package $module;
            delete $INC{$file};
        }
    }

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

   return $self->{params}{file};
}
sub _core {
    
    my $self = shift;

    my $p = $self->{params};

    my $search = $self->{params}{search};
    my $file = $self->{params}{file};

    # pre processor

    my $data;

    if ($self->{params}{pre_proc}){
        my $pre_proc = $self->_pre_proc;

        $data = $pre_proc->($p);

        # for things that don't need to process files 
        # (such as 'module'), return early

        if ($self->{params}{pre_proc_return}){
            return $data;
        }
    }

    # processor

    my $subs = $data;

    # bypass the proc if cache

    my $cache_enabled = $self->_cache_enabled;
    my $cache_safe = $self->_cache_safe;

    if ($cache_enabled && $cache_safe && $self->_cache($p->{file})){
        $subs = $self->_cache($p->{file});
    }
    else {
        $subs = $self->_subs;
    } 
    
    $subs = $subs // 0;

    return if ! $subs;

    $self->{data} = $subs;

    # write to cache

    if ($self->_cache_enabled && ! $self->_cache($p->{file})){
        $self->_cache($p->{file}, $subs);
    }

    # pre engine filter

    if ($self->{params}{pre_filter}){
        for my $pre_filter ($self->_pre_filter){
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
    
    my $PPI_doc = PPI::Document->new($file);
    my $PPI_subs = $PPI_doc->find("PPI::Statement::Sub");

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

        # skip over excluded subs

        next if grep {$name eq $_ } @$exclude;

        if ($include->[0]){
            next if (! grep {$name eq $_ && $_} @$include);
        }

        $subs{$file}{subs}{$name}{start} = $PPI_sub->line_number;
        $subs{$file}{subs}{$name}{start}--;

        my $lines = $PPI_sub =~ y/\n//;

        $subs{$file}{subs}{$name}{end}
          = $subs{$file}{subs}{$name}{start} + $lines;

        my $count_start = $subs{$file}{subs}{$name}{start};
        $count_start--;

        my $sub_line_count
          = $subs{$file}{subs}{$name}{end} - $count_start;

        $subs{$file}{subs}{$name}{num_lines} = $sub_line_count;

        my $line_num = $subs{$file}{subs}{$name}{start};
       
        # pull out just the subroutine from the file 
        # array and attach it to the structure

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
        my $compiler = $pre_proc_module->new;

        if (! $compiler->exists($pre_proc)){
            croak "Devel::Examine::Subs::_pre_proc() speaking...\n\n" .
                  "pre_processor '$pre_proc' is not implemented.\n";
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

            my $cref;

            if (not ref($pf) eq 'CODE'){
                my $pre_filter_module = $self->{namespace} . "::Prefilter";
                my $compiler = $pre_filter_module->new;

                # pre_filter isn't in the dispatch table

                if (! $compiler->exists($pf)){
                    croak "\nDevel::Examine::Subs::_pre_filter() " .
                          "speaking...\n\npre_filter '$pf' is not " .
                          "implemented. '$pre_filter' was sent in.\n";
                }
                
                eval {
                    $cref = $compiler->{pre_filters}{$pf}->();
                };
        
                if ($@){
                    $@ = "\n[Devel::Examine::Subs speaking] " .
                          "dispatch table in " .
                          "Devel::Examine::Subs::Prefilter has a mistyped " .
                          "function as a value, but the key is ok\n\n"
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

    my $engine = $p->{engine} // $self->{params}{engine};

    if (not $engine or $engine eq ''){
        return $struct;
    }

    my $cref;

    if (not ref($engine) eq 'CODE'){

        # engine is a name

        my $engine_module = $self->{namespace} . "::Engine";
        my $compiler = $engine_module->new;

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
    my $pre_proc = $module->new;

    my @pre_procs;

    for (keys %{$pre_proc->_dt}){
        push @pre_procs, $_ if $_ !~ /^_/;
    }
    return @pre_procs;
}
sub pre_filters {

    my $self = shift;
    my $module = $self->{namespace} . "::Prefilter";
    my $pre_filter = $module->new;

    my @pre_filters;

    for (keys %{$pre_filter->_dt}){
        push @pre_filters, $_ if $_ !~ /^_/;
    }
    return @pre_filters;
}
sub engines {

    my $self = shift;
    my $module = $self->{namespace} . "::Engine";
    my $engine = $module->new;
 
    my @engines;

    for (keys %{$engine->_dt}){
        push @engines, $_ if $_ !~ /^_/;
    }
    return @engines;
}
sub has {

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{pre_filter} = 'file_lines_contain';
    $self->{params}{engine} = 'has';
    
    $self->run($p);
}
sub missing {

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{engine} = 'missing';
    
    $self->run($p);
}
sub all {

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{engine} = 'all';
    
    $self->run($p);
}
sub lines {

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{engine} = 'lines';
    
    if ($self->{params}{search} || $p->{search}){
        $self->{params}{pre_filter} = 'file_lines_contain';
    }

    $self->run($p);
}
sub module {

    my $self = shift;
    my $p = $self->_params(@_);

    # set the preprocessor up, and have it return before
    # the building/compiling of file data happens

    $self->{params}{pre_proc} = 'module';
    $self->{params}{pre_proc_return} = 1;

    $self->{params}{engine} = 'module';

    $self->run($p);
}
sub objects {

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{pre_filter} = 'subs';
    $self->{params}{engine} = 'objects';

    $self->run($p);
}
sub search_replace {

    my $self = shift;
    my $p = $self->_params(@_);

    $self->{params}{pre_filter}
      = 'file_lines_contain && subs && objects';

    $self->{params}{engine} = 'search_replace';

    $self->run($p);
}
sub inject_after {

    my $self = shift;
    my $p = $self->_params(@_);

    if (! $p->{injects} && ! $self->{params}{injects}){
        $p->{injects} = 1;
    }

    $self->{params}{pre_filter}
      = 'file_lines_contain && subs && objects';

    $self->{params}{engine} = 'inject_after';

    $self->run($p);
}
sub add_functionality {
    
    my $self = shift;
    my $p = $self->_params(@_);

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

    my $caller = (caller)[1];

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

    my $end_line = $des->run;

    push @TIE_file, @code;
}
sub valid_params {
    my $self = shift;
    return %{$self->{valid_params}};
}
sub _pod{} #vim placeholder 1; 
__END__

=head1 NAME

Devel::Examine::Subs - Get info, search/replace and inject code in
Perl file subs.

=head1 SYNOPSIS

    use Devel::Examine::Subs;

    my $file = 'perl.pl'; # or directory, or Module::Name
    my $search = 'string';

    my $des = Devel::Examine::Subs->new( file => $file );


Get all the subs as objects

    $subs = $des->objects;

    for my $sub (@$subs){
        $sub->name;       # name of sub
        $sub->start;      # number of first line in sub
        $sub->end;        # number of last line in sub
        $sub->line_count; # number of lines in sub
        $sub->code;       # entire sub code from file
        $sub->lines;      # lines that match search term

    }

Get the sub objects within a hash

    my $subs = $des->objects( objects_in_hash => 1 );

    for my $sub_name (keys %$subs) {

        print "$sub_name\n";

        my $sub = $subs->{$sub_name};

        print $sub->start . "\n" .
              $sub->end . "\n";
              ...
    }

Get all sub names in a file

    my $aref = $des->all;


Get all subs containing "string" in the body

    my $aref = $des->has( search => $search );

Search and replace code in subs

    $des->search_replace(
                    search => q/\$template = 'one\.tmpl'",
                    replace => '$template = \'two.tmpl\'',
                  );

Inject code into sub after a search term (preserves previous line's indenting)

    my @code = <DATA>;

    $des->inject_after(
                    search => 'this',
                    code => \@code,
                  );

    __DATA__

    # previously uncaught issue

    if ($foo eq "bar"){
        croak 'big bad error';
    }

Print out all lines in all subs that contain a search term

    my $subs = $des->objects;

    for my $sub (@$subs){
    
        my $lines_with_search_term = $sub->lines;

        for (@$lines_with_search_term){
            my ($line_num, $text) = split /:/, $_, 2;
            say "Line num: $line_num";
            say "Code: $text\n";
        }
    }

The structures look a bit differently when 'file' is a directory.
You need to add one more layer of extraction.

    my $files = $des->objects;

    for my $file (keys %$files){
        for my $sub (@{$files->{$file}}){
            ...
        }
    }

Print all subs within each Perl file under a directory

    my $files = $des->all( file => 'lib/Devel/Examine' );

    for my $file (keys %$files){
        print "$file\n";
        print join('\t', @{$files->{$file}});
    }

All methods can include or exclude specific subs

    my $has = $des->has( include => [qw(dump private)] );

    my $missing = $des->missing( exclude => ['this', 'that'] );

    # note that 'exclude' param renders 'include' invalid


=head1 DESCRIPTION

Gather information about subroutines in Perl files (and in-memory modules),
with the ability to search/replace code, inject new code, get line counts,
get start and end line numbers, access the sub's code and a myriad of other
options.



=head1 METHODS

All public methods take their parameters as a hash (C<key =E<gt> value>).

See the L<PARAMETERS> for the full list of params, and which ones 
are persistent across runs using the same object.



=head2 C<new>

Mandatory parameters: C<file =E<gt> $filename>

Instantiates a new object. If C<$filename> is a directory, we'll iterate
through it finding all Perl files. If C<$filename> is a module name
(eg: C<Data::Dumper>), we'll attempt to load the module, extract the file for
the module, and load the file. CAUTION: this will be a production C<%INC> file
so be careful.

Only specific params are guaranteed to stay persistent throughout a run on the
same object, and are best set in C<new()>. These parameters are C<file>,
C<extensions>, C<cache>, C<regex>, C<copy>, C<no_indent> and C<diff>.





=head2 C<all>

Mandatory parameters: None

Returns an array reference containing the names of all subroutines found in
the file.






=head2 C<has>

Mandatory parameters: C<search =E<gt> 'term'>

Returns an array reference containing the names of the subs where the
subroutine contains the search text.




=head2 C<missing>

Mandatory parameters: C<search =E<gt> 'term'>

The exact opposite of has.




=head2 C<objects>

Mandatory parameters: None

Optional parameters: C<objects_in_hash =E<gt> 1>

Returns an array reference of subroutine objects. If the optional
C<objects_in_hash> is sent in with a true value, the objects will be returned
in a hash reference where the key is the sub's name, and the value is the sub
object.

See L<SYNOPSIS> for the structure of each object.




=head2 C<module>

Mandatory parameters: C<module =E<gt> 'Module::Name'>

Returns an array reference containing the names of all subs found in the
module's namespace symbol table.




=head2 C<lines>

Mandatory parameters: C<search =E<gt> 'text'>

Gathers together all line text and line number of all subs where the
subroutine contains lines matching the search term.

Returns a hash reference with the subroutine name as the key, the value being
an array reference which contains a hash reference in the format line_number
=E<gt> line_text.




=head2 C<search_replace>

Mandatory parameters: C<search =E<gt> 'this', replace =E<gt> 'that'>

Core optional parameter: C<copy =E<gt> 'filename.txt'>

Search for lines that contain certain text, and replace the search term with
the replace term. If the optional parameter 'copy' is sent in, a copy of the
original file will be created in the current directory with the name
specified, and that file will be worked on instead. Good for testing to ensure
The Right Thing will happen in a production file.

This method will create a backup copy of the file with the same name appended
with '.bak', but don't confuse this feature with the 'copy' parameter.






=head2 C<inject_after>

Mandatory parameters: C<search =E<gt> 'this', code =E<gt> \@code>

Injects the code in C<@code> into the sub within the file, where the sub
contains the search term. The same indentation level of the line that contains
the search term is used for any new code injected. Set C<no_indent> parameter
to a true value to disable this feature.

By default, an injection only happens after the first time a search term is
found. Use the C<injects> parameter (see L<PARAMETERS>) to change this
behaviour. Setting to a positive integer beyond 1 will inject after that many
finds. Set to a negative integer will inject after all finds.

The C<code> array should contain one line of code (or blank line) per each
element. (See L<SYNOPSIS> for an example). The code is not manipulated prior
to injection, it is inserted exactly as typed. Best to use a heredoc,
C<__DATA__> section or an external text file for the code.



Optional parameters:

=over 4



=item C<copy>

See C<search_replace()> for a description of how this parameter is used.

=item C<injects>

How many injections do you want to do per sub? See L<PARAMETERS> for more
details.

=back



=head2 C<pre_procs>

Returns a list of all available pre processor modules.



=head2 C<pre_filters>

Returns a list of all available built-in pre engine filter modules.



=head2 C<engines>

Returns a list of all available built-in 'engine' modules.


=head2 C<valid_params>

Returns a hash where the keys are valid parameter names, and the value is a
bool where if true, the parameter is persistent (remains between calls on the
same object) and if false, the param is transient, and will be made C<undef>
after each method call finishes.


=head2 C<run>

Parameter format: Hash reference

All public methods call this method internally. This is the only public method
that takes its parameters as a single hash reference. The public methods set certain
variables (filters, engines etc). You can get the same effect programatically
by using C<run()>. Here's an example that performs the same operation as the
C<has()> public method:

    my $params = {
            search => 'text',
            pre_filter => 'file_lines_contain',
            engine => 'has',
    };

    my $return = $des->run($params);

This allows for very fine-grained interaction with the application, and makes
it easy to write new engines and for testing.





=head2 C<add_functionality>

WARNING!: This method is highly experimental and is used for developing
internal processors only. Only 'engine' is functional, and only half way.

While writing new processors, set the processor type to a callback within the
local working file. When the code performs the actions you want it to, put a
comment line before the code with C<#<des>> and a line following the code with
C<#</des>>. DES will slurp in all of that code live-time, inject it into the
specified processor, and configure it for use. See
C<examples/write_new_engine.pl> for an example of creating a new 'engine'
processor.




Parameters:

=over 4

=item C<add_functionality>

Informs the system which type of processor to inject and configure. Permitted
values are 'pre_proc', 'pre_filter' and 'engine'.

=item C<add_functionality_prod>

Set to a true value, will update the code in the actual installed Perl module
file, instead of a local copy.

=back





Optional parameters:

=over 4

=item C<copy> 

Set it to a new file name which will be a copy of the specified file, and only
change the copy. Useful for verifying the changes took properly.

=back







=head1 PARAMETERS

There are various parameters that can be used to change the behaviour of the
application. Some are persistent across calls, and others aren't. You can
change or null any/all parameters in any call, but some should be set in the
C<new()> method (set it and forget it).

The following list are persistent parameters, which need to be manually
changed or nulled. Consider setting these in C<new()>.

=over 4

=item C<file>

State: Persistent

Default: None

The name of a file, directory or module name. Will convert module name to a
file name if the module is installed on the system. It'll C<require> the
module temporarily and then 'un'-C<require> it immediately after use.

If set in C<new()>, you can omit it from all subsequent method calls until you
want it changed. Once changed in a call, the updated value will remain
persistent until changed again.


=item C<extensions>

State: Persistent

Default: C<[qw(pm pl)]>

By default, we load only C<*.pm> and C<*.pl> files. Use this parameter to load
different files. Only useful when a directory is passed in as opposed to a
file. This parameter is persistent until manually reset and should be set in
C<new()>.

Values: Array reference where each element is the name of the extension
(less the dot). For example, C<[qw(pm pl)]> is the default.

=item C<cache>

State: Persistent

Default: Undefined

If multiple calls on the same object are made, caching will save the
file/directory/sub information, saving tremendous work for subsequent calls.
This is dependant on certain parameters not changing between calls.

Set to a true value (1) to enable. Best to call in the C<new> method.


=item C<copy>

State: Persistent

Default: None

For methods that write to files, you can optionally work on a copy that you
specify in order to review the changes before modifying a production file.

Set this parameter to the name of an output file. The original file will be
copied to this name, and we'll work on this copy.


=item C<regex>

State: Persistent

Default: Enabled

Set to a true value, all values in the 'search' parameter become regexes. For
example with regex on, C</thi?s/> will match "this", but without regex, it
won't. Without 'regex' enabled, all characters that perl treats as special
must be escaped. This parameter is persistent; it remains until reset
manually.


=item C<no_indent>

State: Persistent

Default: Disabled

In the processes that write new code to files, the indentation level of the
line the search term was found on is used for inserting the new code by
default. Set this parameter to a true value to disable this feature and set
the new code at the beginning column of the file.

=item C<diff>

State: Persistent

Not yet implemented. 

Compiles a diff after each edit using the methods that edit files.

=back

The following parameters are not persistent, ie. they get reset before
entering the next call on the DES object. They must be passed in to each
subsequent call if the effect is still desired.


=over 4

=item C<include>

State: Transient

Default: None

An array reference containing the names of subs to include. This
(and C<exclude>) tell the Processor phase to generate only these subs,
significantly reducing the work that needs to be done in subsequent method
calls.



=item C<exclude>

State: Transient

Default: None

An array reference of the names of subs to exclude. See C<include> for further
details.

Note that C<exclude> renders C<include> useless.




=item C<injects>

State: Transient

Default: 1

Informs C<inject_after()> how many injections to perform. For instance, if a
search term is found five times in a sub, how many of those do you want to
inject the code after?

Default is 1. Set to a higher value to achieve more injects. Set to a negative
integer to inject after all.



=item C<pre_proc_dump>, C<pre_filter_dump>, C<engine_dump>, C<cache_dump>,
C<core_dump>

State: Transient

Default: Disabled

Set to 1 to activate, C<exit()>s after completion.

Print to STDOUT using Data::Dumper the structure of the data following the
respective phase. The C<core_dump> will print the state of the data, as well
as the current state of the entire DES object.

NOTE: The 'pre_filter' phase is run in such a way that pre-filters can be
daisy-chained. Due to this reason, the value of C<pre_filter_dump> works a
little differently. For example:

    pre_filter => 'one && two';

...will execute filter 'one' first, then filter 'two' with the data that came
out of filter 'one'. Simply set the value to the number that coincides with
the location of the filter. For instance, C<pre_filter_dump =E<gt> 2;> will
dump the output from the second filter and likewise, C<1> will dump after the
first.

For C<cache_dump>, if it is set to one, it'll dump cache but the application
will continue. Set this parameter to an integer larger than one to have the
application C<exit> immediately after dumping the cache to STDOUT.


=item C<pre_proc_return>, C<pre_filter_return>, C<engine_return>

State: Transient

Default: Disabled

Returns the structure of data immediately after being processed by the
respective phase. Useful for writing new 'phases'. (See "SEE ALSO" for
details).

NOTE: C<pre_filter_return> does not behave like C<pre_filter_dump>. It will
only return after all pre-filters have executed.




=item C<config_dump>

State: Transient

Default: Disabled

Prints to C<STDOUT> with C<Data::Dumper> the current state of all loaded
configuration parameters.




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

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the
Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
