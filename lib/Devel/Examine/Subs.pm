package Devel::Examine::Subs;

use 5.10.0;
use strict;
use warnings;

our $VERSION = '0.06';

sub has {
    my $self    = shift;
    my $p       = shift;

    if ( ! exists $p->{ search } or $p->{ search } eq '' ){
        return ();
    }
    $p->{ want_what } = 1;
    return @{ _get( $p ) };
}
sub missing {
    my $self    = shift;
    my $p       = shift;

    if ( ! exists $p->{ search } or $p->{ search } eq '' ){
        return ();
    }
    $p->{ want_what } = 0;
    return @{ _get( $p ) };
}
sub all {
    my $self    = shift;
    my $p       = shift;

    $p->{ want_what } = 2;
    return @{ _get( $p ) };
}
sub _get {
    
    my $p           = shift;
    my $file        = $p->{ file };
    my $search      = $p->{ search }; 
    my $want_what   = $p->{ want_what }; # 0=missing 1=has >1=all
    
    my $subs = _subs({
                        file => $file,
                        want => $search,
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
        next if ! $name or ! $want;
        $subs{ $name } = 1 if $line =~ /$want/;
    }
    return \%subs;
}

1;
__END__

=head1 NAME

Devel::Examine::Subs - Get names of subroutines containing certain text 

=head1 SYNOPSIS

    use Devel::Examine::Subs;

    my $file = 'perl.pl';
    my $find = 'function(';

    # list of sub names where the sub contains the text "function("
    my @has = Devel::Examine::Subs->has({ file => $file, search => $find });
    
    # same as has(), but returns the opposite
    my @missing = Devel::Examine::Subs->missing({ file => $file, search => $find });

    # get all sub names in a file
    my @subs = Devel::Examine::Subs->all({ file => $file });



=head1 DESCRIPTION

Reads into Perl program and module files returning the names
of its subroutines, optionally limiting the names returned to
subs that contain or do not contain specified text.


=head1 METHODS

=head2 has({ file => $filename, search => $text })

Takes the name of a file to search, and the text you want to
search for within each sub. Useful to find out which subs call
other methods.

Returns a list of names of the subs where the subroutine containes
the text. In scalar context, returns the count of subs containing
the found text.

=head2 missing({ file => $filename, search => $text })

The exact opposite of has.

=head2 all({ file => $filename })

Returns a list of the names of all subroutines found in the file.


=head1 CAVEATS

subs that begin indented (such as closures and those within other
blocks) will not be counted.


=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Examine::Subs

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
