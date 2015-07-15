package Devel::Examine::Subs;

use strict;
use warnings;

our $VERSION = '1.15';

BEGIN {
    
    # check for and load PPI

    my @use_err;

    eval { require PPI; import PPI; };
    push @use_err, $@ if $@;
   
    if (not $@){ 
        eval { require PPI::Dumper; import PPI::Dumper; };
        push @use_err, $@ if $@;
    }

    if (@use_err and $use_err[0] =~ /PPI\.pm/){
        print "PPI can't be found and won't be used.\n";
    }
    elsif (@use_err) {
        print "PPI found, but PPI::Dumper is missing. " .
              "PPI won't be used.\n";
    }
}
            
sub new {
    my $self = {};
    bless $self, shift;
    
    # set PPI status

    $self->{PPI} = 0;

    my ($ppi, $ppi_dump) = qw(PPI.pm PPI/Dumper.pm);

    if ($INC{$ppi} and $INC{$ppi_dump}){
        $self->{PPI} = 1;
    }

    return $self;
}
sub has {
    my $self    = shift;
    my $p       = shift;

    if (! -f $p->{file}){
        die "Invalid file supplied: $p->{file} $!";
    }

    if (! exists $p->{search} or $p->{search} eq ''){
        return ();
    }

    if ($p->{lines}){    
        $p->{want_what} = 'has_lines';
        return %{$self->_get($p)};
    }
    else {
        $p->{want_what} = 'has';
        return @{$self->_get($p)};
    }

}
sub missing {
    my $self    = shift;
    my $p       = shift;

    if (! -f $p->{file}){
        die "Invalid file supplied: $p->{file} $!";
    }

    if (! exists $p->{search} or $p->{search} eq ''){
        return ();
    }
    $p->{want_what} = 'missing';
    return @{$self->_get($p)};
}
sub all {
    my $self    = shift;
    my $p       = shift;

    $p->{want_what} = 'all';
    return @{$self->_get($p)};
}
sub module {
    my $self = shift;
    my $p = shift;

    $p->{want_what} = 'module';
    return @{$self->_get($p)};
}
sub line_numbers {
    my $self = shift;
    my $p = shift;

    $p->{want_what} = 'line_numbers';

    if ($p->{get} and $p->{get} =~ /obj/){
        return $self->sublist($p);
    }
    else {
        return $self->_get($p);
    }
}
sub _objects {

    my $self = shift;
    my $subs = shift;

    my @sub_list;

    package Devel::Examine::Subs::Sub;
        sub new {
            my $class = shift;
            my $data = shift;
            my $name = shift;

            my $self = bless {}, $class;

            $self->{data} = $data;
            $self->{name} = $name || '';
            $self->{start_line} = $data->{start};
            $self->{stop_line} = $data->{stop};
            if ($data->{stop} and $data->{start}){
                $self->{count_line} = $data->{stop} - $data->{start};
            }
                     
            return $self;
        }
        sub name {
            my $self = shift;
            return $self->{name};
        }
        sub start {
            my $self = shift;
            return $self->{start_line};
        }
        sub stop {
            my $self = shift;
            return $self->{stop_line};
        }
        sub count {
            my $self = shift;
            return $self->{count_line};
        }

    for my $sub (keys %$subs){
        my $obj = Devel::Examine::Subs::Sub->new($subs->{$sub}, $sub);
        push @sub_list, $obj;
    }

    $self->{sublist} = \@sub_list;
}
sub sublist {
    my $self = shift;
    my $p = shift;

    $p->{want_what} = 'sublist';

    $self->_get($p);

    return $self->{sublist};
}
sub _get {
   
    my $self        = shift;
    my $p           = shift;
    my $file        = $p->{file};
    my $search      = $p->{search}; 
    my $want_what   = $p->{want_what};

    # do module() first, as we don't need to search in
    # any files

    # want_what eq module

    if ($want_what eq 'module'){
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

    my $subs = $self->_subs({
                        file => $file,
                        search => $search,
                        want_what => $want_what,
                    });

    # configure sub objects for sublist

    if ($want_what eq 'sublist'){
        $self->_objects($subs);
    }

    # return early if we want all sub names
    
    return [ sort keys %$subs ] if $want_what eq 'all';

    # return if we want line nums

    if ($want_what eq 'line_numbers'){
        my @line_nums;

        for my $sub (keys %$subs){
            delete $subs->{$sub}{found};
        }
        return $subs;
    }

    # want_what eq sublist

    if ($want_what eq 'sublist'){
        return $subs;
    }

    # want_what eq has_lines

    if ($want_what eq 'has_lines'){

        my %data;

        for my $sub (keys %$subs){
            if ($subs->{$sub}{lines}){
                $data{$sub} = $subs->{$sub}{lines};
            }
        }

        return \%data;
    }         
  
    my (@has, @hasnt);

    for my $sub (keys %$subs){
        push @has,   $sub if $subs->{$sub}{found};
        push @hasnt, $sub if ! $subs->{$sub}{found};
    }

    return \@has if $want_what eq 'has';
    return \@hasnt if $want_what eq 'missing';
}
sub _subs {

    my $self = shift;
    my $p       = shift;
    my $file    = $p->{file};
    my $search    = $p->{search} || '';
    my $want_what = $p->{want_what};

    if ($self->_PPI()){
        $self->_load_PPI($p);
        print "$_\n" for @{$self->{PPI_subs}};
    }

    open my $fh, '<', $file or die "Invalid file supplied: $!";

    my %subs;
    my $name; 
    
    while (my $line = <$fh>){
        if ($line =~ /^sub\s/){
            $name = (split /\s+/, $line)[1];
            $subs{$name}{start} = $.;
            $subs{$name}{found} = 0;

            # mark the end of the sub or we'll go past
            # the last one into POD

            $subs{$name}{done} = 0; 

            next;
        }

        if ($name and $line =~ /^\}/){
            $subs{$name}{stop} = $.;
            $subs{$name}{done} = 1;
        }

        if (! $name or $subs{$name}{done} == 1){
            next;
        }

        next if $subs{$name}{found};

        if ($line =~ /$search/){
            if ($want_what ne 'has_lines'){
                $subs{$name}{found} = 1;
            }
            push @{$subs{$name}{lines}}, {$. => $line};
        }
    }
    
    return \%subs;
}
sub _PPI {
    my $self = shift;
    return $self->{PPI};
}
sub _load_PPI {
    my $self = shift;
    my $p = shift;

    my $file = $p->{file};

    return if not $self->_PPI();

    my $ppi_doc = PPI::Document->new($file);
    my $ppi_dump = PPI::Dumper->new($ppi_doc);

    my @subs =
        map {$_->name}
        @{$ppi_doc->find(
                sub {
                        $_[1]->isa('PPI::Statement::Sub');
                }
        )};

    $self->{PPI_subs} = \@subs;
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

    # all subs containing "string", along with the data in the line
    my %data = $des->has({file => $file, search => $find, lines => 1})

    # opposite of has
    my @missing = $des->missing({file => $file, search => $find}); 
    
    # all subs with their corresponding start/end line num
    my $href = $des->line_numbers({file => $file}) 
    
    # return the subs of an in-memory module instead of a file
    my @subs = $des->module({module => 'Devel::Examine::Subs'});

    # return an aref of subroutine objects

    $aref = $des->sublist(...)

    for my $sub (@$aref){    
        print $sub->name() # name of sub
        print $sub->start() # first line of sub
        print $sub->stop() # last line of sub
        print $sub->count() # number of lines in sub
    }

=head1 DESCRIPTION

Reads into Perl program and module files (or modules in memory) 
returning the names of its subroutines, optionally limiting 
the names returned to subs that contain or do not contain 
specified text, or the start and end line numbers of the sub.

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
