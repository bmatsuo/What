#!/usr/bin/env perl
package What::Prompt::Choose;

# Use perldoc to read documentation

# include some core modules
use strict;
use warnings;

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
    => (isa => 'ArrayRef[Str]',
        is => 'rw',
        required => 1,
        trigger => \&_choices_set_,);
has 'stringify' 
    => (isa => 'CodeRef', 
        is => 'rw', 
        # By default, the stringify sub reference just returns its arguments.
        default => sub {return sub {return @_}});

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

# Subroutine: $choice_prompt->preprompt_text()
# Type: INSTANCE METHOD
# Purpose: Create a string of the list choices, and prompt text
sub preprompt_text {
    my $self = shift;
    my @choices = @{$self->choices};
    my @choice_head = (
        '+------------------------------------------------------------------------------+',
        '| {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<} |',
        $self->question,
        '+------------------------------------------------------------------------------+',
    );
    my $choice_format =
        '| {>>>}   {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |';
    my $choice_foot =
        '+------------------------------------------------------------------------------+';
    my @choice_rows 
        = map {
            ($choice_format, 
                "[$_]", $self->stringify->($choices[$_]), $choice_foot)
        } (0 .. $#choices);
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
        return (looks_like_number $c && 0 <= $c && $c < @choices)};
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
