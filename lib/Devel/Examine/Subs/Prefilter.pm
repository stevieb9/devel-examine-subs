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
        objects => \&objects,
        _default => \&_default,
        _test => \&_test,
        _test_bad => \&_test_bad,
        end_of_last_sub => \&end_of_last_sub,
    };

    return $dt;
}
sub exists {
    my $self = shift;
    my $string = shift;

    if (exists $self->{pre_filters}{$string}){
        return 1;
    }
    else {
        return 0;
    }
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
                @{ $s->{$f}{subs}{$sub}{file} } = @{ $s->{$f}{TIE_file} };
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
                for (@{$s->{$f}{subs}{$sub}{TIE_file_sub}}){
                    if ($_ and /\Q$search/){
                        $found++;
                        push @has, $_;
                     }
                }
                if (! $found){
                    delete $s->{$f}{subs}{$sub};                
                    next;
                }
                $s->{$f}{subs}{$sub}{TIE_file_sub} = \@has;
            }
        }
        return $struct;
    };
}
sub end_of_last_sub {
    
    return sub {
        
        my $p = shift;
        my $struct = shift;

        my @last_line_nums;

        for my $sub (@$struct){
            push @last_line_nums, $sub->{end};
        }

        @last_line_nums = sort {$a<=>$b} @last_line_nums;

        return $last_line_nums[-1];

    };
}
sub _test {

    return sub {
        my $struct = shift;
        return $struct;
    };
}
sub objects {

    # uses 'subs' pre_filter

    return sub {

        my $p = shift;
        my $struct = shift;

        my @return;

        return if not ref($struct) eq 'ARRAY';

        my $file = $p->{file};
        my $search = $p->{search};
        my $lines;

        my $des_sub;

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

