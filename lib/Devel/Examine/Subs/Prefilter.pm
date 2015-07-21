package Devel::Examine::Subs::Prefilter;
use strict;
use warnings;

use Carp;
use Data::Dumper;

our $VERSION = '1.18';

sub new {

    my $self = {};
    bless $self, shift;

    my $struct = shift;

    $self->{pre_filters} = $self->_dt();
    
    return $self;
}
sub _dt {

    my $self = shift;

    my $dt = {
        file_lines_contain => \&file_lines_contain,
        subs => \&subs,
        _default => \&_default,
        _test => \&_test,
        _test_bad => \&_test_bad,
        objects => \&objects,
    };

    return $dt;
}
sub subs {
    
    return sub {

        my $p = shift;
        my $struct = shift;
        
        my $s = $struct;
        my @subs;

        my $search = $p->{search};

        for my $f (keys %$s){
        
            for my $sub (keys %{$s->{$f}{subs}}){
                
                if ($search && $sub eq $search){
                    next;
                }
                $s->{$f}{subs}{$sub}{start}++;
                $s->{$f}{subs}{$sub}{end}++;
                $s->{$f}{subs}{$sub}{name} = $sub;
                @{ $s->{$f}{subs}{$sub}{file} } = @{ $s->{$f}{TIE_perl_file} };
                push @subs, $s->{$f}{subs}{$sub};
            }
        }
        return \@subs;
    };
} 
sub file_lines_contain {

    return sub {

        my $p = shift;
        my $struct = shift;

        my $search = $p->{search};

        my $s = $struct;


        if (not $search){
            return $struct;
        }

        for my $f (keys %$s){
            for my $sub (keys %{$s->{$f}{subs}}){
                my $found = 0;
                my @has;
                for (@{$s->{$f}{subs}{$sub}{TIE_perl_file_sub}}){
                    if ($_ and /\Q$search/){
                        $found++;
                        push @has, $_;
                     }
                }
                if (! $found){
                    delete $s->{$f}{subs}{$sub};                
                    next;
                }
                $s->{$f}{subs}{$sub}{TIE_perl_file_sub} = \@has;
            }
        }
        return $struct;
    };
}
sub objects {

    # uses 'subs' pre_filter

    return sub {

        my $p = shift;
        my $struct = shift;

        my @return;

        my $des_sub;
       
        return if not ref($struct) eq 'ARRAY';

        for my $sub (@$struct){

            # if the name of the callback method is mistyped in the
            # dispatch table, this will be triggered

            $des_sub
              = Devel::Examine::Subs::Sub->new($sub, $sub->{name});

            #FIXME: this eval catch catches bad dispatch and "not a hashref"

            if ($@){
                print "dispatch table in engine has a mistyped function value\n\n";
                confess $@;
            }

            push @return, $des_sub;
        }

        return \@return;
    };
}
sub _test {

    return sub {
        my $struct = shift;
        return $struct;
    };
}
