package Devel::ExamineSubs;

use 5.10.0;
use strict;
use warnings;

our $VERSION = '0.04';

package Devel::ExamineSubs;

sub has {
    return @{ _get( @_, 1 ) };
}
sub missing {
    return () if $_[2] eq '';
    return @{ _get( @_, 0 ) };
}
sub all {
    push @_, '' if @_ == 2;
    return @{ _get( @_, 2 ) };
}
sub _get {
    
    my $self      = shift;
    my $file      = (@_ == 3) ? shift : die "Invalid number of params to _get(): $!";
    my $want_text = (@_ == 2) ? shift : ''; 
    my $want_what = shift; # 0=missing 1=has >1=all
    
    $want_text = 0xffff0c0e if $want_text eq '';

    my $subs = _subs({
                        file => $file,
                        want => $want_text,
                    });

    my ( @has, @hasnt );

    while ( my ($k,$v) = each %$subs ){
        push @has,   $k if $v;
        push @hasnt, $k if ! $v;
    }

    return [ sort keys %$subs ] if $want_what > 1;

    if ( $want_what ){
        return \@has;
    }
    else {
        return \@hasnt;
    }
}
sub _subs {

    my $p       = shift;
    my $file    = $p->{ file };
    my $want    = $p->{ want };
    open my $fh, '<', $file or die "Invalid file supplied: $!";

    my %subs;
    my $name; 

    while ( my $line = <$fh> ){
        if ( $line =~ /^sub\s/ ){
            $name = (split /\s+/, $line)[1];
            $subs{ $name } = 0;
            next;
        }
        next if ! $name;
        $subs{ $name } = 1 if $line =~ /$want/;
    }
    return \%subs;
}

1;
__END__

=head1 NAME

Devel::ExamineSubs - Get names of subroutines containing certain text 

=head1 SYNOPSIS

    use Devel::ExamineSubs;

    my $file = 'perl.pl';
    my $find = 'function(';

    # list of sub names where the sub contains the text "function("
    my @has = Devel::ExamineSubs->has( $file, $find );
    
    # same as has(), but returns the opposite
    my @missing = Devel::ExamineSubs->missing( $file, $find );

    # get all sub names in a file
    my @subs = Devel::ExamineSubs->all( $file );



=head1 DESCRIPTION

Reads into Perl program and module files returning the names
of its subroutines, optionally limiting the names returned to
subs that contain or do not contain specified text.


=head1 METHODS

=head2 has( $filename, $text )

Takes the name of a file to search, and the text you want to
search for within each sub.

Returns a list of names of the subs where the subroutine containes
the text. In scalar context, returns the count of subs containing
the found text.

=head2 missing( $filename, $text )

The exact opposite of has.

=head2 all( $filename )

Returns a list of the names of all subroutines found in the file.


=head1 CAVEATS

subs that begin indented (such as closures and those within other
blocks) will not be counted.


=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::ExamineSubs

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
