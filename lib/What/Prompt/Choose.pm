#!/usr/bin/env perl
package What::Prompt::Choose;

# Use perldoc to read documentation

# include some core modules
use strict;
use warnings;
use POSIX qw{ceil};
use What::Exceptions::Common;

# include CPAN modules
use Perl6::Form;
our $VERSION = '0.0_1';

use Exception::Class (
    'NoChoicesException'
);

# include any private modules
use What;
use Moose;
use Scalar::Util qw{looks_like_number};
extends 'What::Prompt::Base';

has 'question'
    => (isa => 'Str',
        is => 'rw',
        default => "Which one?");
has 'choices' 
    => (isa => 'ArrayRef',
        is => 'rw',
        required => 1,
        trigger => \&_choices_set_,);
has 'stringify' 
    => (isa => 'CodeRef', 
        is => 'rw', 
        # By default, the stringify sub reference just returns its arguments.
        default => sub {return sub {return @_}});
has 'should_page'
    => (isa => 'Bool', is => 'rw', default => 0);
has 'page_number'
    => (isa => 'Int', is => 'rw', default => 0);
has 'results_per_page'
    => (isa => 'Int', is => 'rw', default => 10);

### INSTANCE METHOD
# Subroutine: chosen
# Usage: $cp->chosen(  )
# Purpose:
#   Return the object last chosen by the user during 
#   $cp->prompt_user().
#   This acts as a translation between choosen indices and objects.
# Returns:
#   An element of $cp->choices if $cp->response is defined;
#   an undefined value otherwise.
# Throws: Nothing
sub chosen {
    my $self = shift;
    my $i = $self->response;
    return if !defined $i;
    return $self->choices->[$i];
}

sub _choices_set_ {
    my ($self, $c_ref, $old_ref) = @_;
    if (@{$c_ref} == 0) {
        $self->choices($old_ref) if defined $old_ref && @{$old_ref} > 0;
        NoChoicesException->throw( error=>"Empty choice list");
    }
}

# Subroutine: $choice->default()
# Type: INSTANCE METHOD
# Returns: The default choice when nothing is given.
sub default {
    return 0;
}

sub num_pages {
    my $self = shift;
    ceil(scalar (@{$self->choices}) / $self->results_per_page);
};

# Subroutine: $choice_prompt->preprompt_text()
# Type: INSTANCE METHOD
# Purpose: Create a string of the list choices, and prompt text
sub preprompt_text {
    my $self = shift;
    my @choices = @{$self->choices};
    my $num_pages = $self->num_pages;

    my ($page_start, $page_end) = (0, $#choices);
    my $there_are_more_choices = $num_pages > $self->page_number + 1;
    my $there_are_previous_choices = $self->page_number > 0;
    my $page = $self->page_number;
    my $rpp = $self->results_per_page;
    if ($self->should_page) {
        $page_start = $page * $rpp;
        $page_end = $page_start + $rpp - 1
            if $there_are_more_choices;
    }

    my @page_indices = ($page_start ... $page_end);
    my @page_choices = @choices[@page_indices];
    #print {\*STDERR} "CHOICES: @page_choices.\n";

    my @choice_head = (
        '+------------------------------------------------------------------------------+',
        '| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |',
        $self->question,
        '+------------------------------------------------------------------------------+',
    );
    my $choice_format =
        '| {>>>}   {""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""} |';
    my $choice_foot =
        '+------------------------------------------------------------------------------+';

    my @choice_rows = map {
        ($choice_format, 
            "[$page_indices[$_]]", $self->stringify->($page_choices[$_]), $choice_foot)
    } (0 ... $#page_choices);

    if ($there_are_previous_choices) {
        if ($self->page_number > 1) {
            my @first_page_row = ($choice_format, "[<<]", "First page.", $choice_foot);
            #print {\*STDERR} form @first_page_row;
            push @choice_rows, @first_page_row;
        }

        my $prev_page_str = sprintf ("Previous page; (%d/%d).", $page , $num_pages);
        my @prev_page_row = ($choice_format, "[<]", $prev_page_str, $choice_foot);
        #print {\*STDERR} form @prev_page_row;
        push @choice_rows, @prev_page_row;
    }
    if ($there_are_more_choices) {
        my $next_page_str = sprintf ("Next page; (%d/%d).", $page + 2, $num_pages);
        my @next_page_row = ($choice_format, "[>]", $next_page_str, $choice_foot);
        #print {\*STDERR} form @next_page_row;
        push @choice_rows, @next_page_row;

        if ($num_pages > $self->page_number + 2) {
            my @last_page_row = ($choice_format, "[>>]", "Last page.", $choice_foot);
            #print {\*STDERR} form @last_page_row;
            push @choice_rows, @last_page_row;
        }
    }

    my $text = form (@choice_head, @choice_rows, );
    chomp $text;

    return $text;
}

# Subroutine: $choice_prompt->text()
# Type: INSTANCE METHOD
# Purpose: Get text for prompt choice.
sub text {
    my $self = shift;
    my $text = 
        '|                                                                              |'
        . "\r| Please enter a choice [" . $self->default() . "]:";
    return $text;
}

sub validator {
    my $self = shift;
    my @choices = @{$self->choices};
    return sub { 
        my $c = shift;
        if ($self->should_page && $self->num_pages > 1) {
            if ($self->page_number + 1 < $self->num_pages) {
                return 1 if $c =~ m/\A [>]{1,2} \z/xms;
            }
            if ($self->page_number > 0) {
                return 1 if $c =~ m/\A [<]{1,2} \z/xms;
            }
        }
        return (looks_like_number $c && 0 <= $c && $c < @choices );
    };
}

sub parser {
    my $self = shift;
    return sub {
        my $c = shift;
        if ($c =~ m/\A (?: [>]{1,2} | [<]{1,2} ) \z/xms) {
            my $new_page 
                = $c eq '<<' ? 0
                : $c eq '<' ? $self->page_number - 1
                : $c eq '>' ? $self->page_number + 1
                : $c eq '>>' ? $self->num_pages - 1
                : undef;
            if (!defined $new_page) {
                UnknownError->throw(error => "Can't figure out new page number.");
            }
            $self->page_number($new_page);
            return $self->prompt_user();
        }
        return $c;
    };
}

1;
__END__

=head1 NAME

Prompt.pm
-- Module for command-line prompting in What scripts.

=head1 VERSION

Version 0.0_3
Originally created on 07/14/10 18:38:01

=head1 ABSTRACT

    use What::Prompt;
    
    # Check if a number is an integer.
    sub is_int { 
        return $_[0] =~ m/^-?\d+\n?$/;
    }
    
    # Create a prompt to ask for a number.
    my $p = What::Prompt->new( 
        {     
            text => "Enter a number:", 
            validator => \&is_int, 
        }
    );   
    
    # Execute multiple prompts.
    my $x = $p->prompt_user();
    my $y = $p->prompt_user();
    
    # Do some intense computations...
    my $prod = $x * $y; 
    
    # Print the result for the user.
    print "The two numbers' product is $prod.\n";

=head1 DESCRIPTION

This Module contains the What::Prompt class of object. It can handle
prompting the user through STDOUT and reading a response via STDIN. It
can also handle automatic retrying of invalid responses.

=head1 BUGS

=over

=back

=head1 AUTHOR

dieselpowered

=head1 COPYRIGHT & LICENSE

(c) 2010 by The What team.

This file is part of What.

What is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

What is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with What.  If not, see <http://www.gnu.org/licenses/>.

=cut
