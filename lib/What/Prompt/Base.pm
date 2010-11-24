#!/usr/bin/env perl
package What::Prompt::Base;

# Use perldoc to read documentation

# include some core modules
use strict;
use warnings;

# include CPAN modules
use Readonly;
use Term::ReadLine;
use IO::Handle;

our $VERSION = '0.0_3';
# include any private modules
use What;

use Exception::Class (
    'ValueException',
    'ArgumentException',
    'PromptException' => {
        description => 'A parent class for all prompt exceptions.'
    },
    'PromptTextException' => {
        isa => 'PromptException',
        fields => [qw{text}],
        description => 'Thrown when prompt text is invalid (e.g. empty).',
    },
    'PromptEOFException' => {
        isa => 'PromptException',
        fields  => [qw{resp}],
        description => 
            'Thrown if unexpected EOFs are read. Has a partial response.',
    },
);

use Moose;

my $prompt_count = 0;

sub preprompt_text { return "" };
sub text { return "Please enter some text:" };
sub validator { return sub {1} };
sub default { return q{} };

has 'is_multiline'
    => (isa => 'Bool', is => 'rw', default => 0);
has 'terminator'
    => (isa => 'Str', is => 'rw', default => q{.});
has 'terminal'
    => (# isa => 'Term::ReadLine', 
        is => 'ro', 
        default => sub {Term::ReadLine->new(q{WhatPrompt } . $prompt_count++)});

# Subroutine: $prompt->_retry_prompt_user($previous_response)
# Type: INTERNAL UTILITY
# Purpose: 
#   Attempt to reissue the same prompt due to a misunderstoop response.
# Returns: 
#   The reissued prompt's user response
sub _retry_prompt_user {
    my $self = shift;
    my $resp = shift;
    print "I couldn't understand '$resp'.$/";
    return $self->prompt_user();
}

# Subroutine: $prompt->prompt_user()
# Type: INSTANCE METHOD
# Purpose: 
#   Print prompt text to STDOUT and read a response from the user.
# Returns: 
#   Choice index.
sub prompt_user {
    my $self = shift;
    my $preprompt = $self->preprompt_text();
    my $text = $self->text();
    my $default = $self->default();
    my $input_is_multiline = $self->is_multiline;
    my $terminator = $self->terminator;
    my $is_valid = $self->validator();
    my $term = $self->terminal;
    my $resp = "";

    my $terminate_help 
        = join q{}, 
            qq{(stop input with a line "$terminator<Enter>")}, ;

    my $prompt_text 
        = $text.($input_is_multiline ? "$/$terminate_help$/" : q{});

    my $line_count = 0;

    if ($preprompt =~ m/./xms) {
        print "$preprompt\n";
        STDOUT->flush();
    }

    # Read user response.
    my $rline;
    while (1) {
        $rline = $term->readline($prompt_text);
        last if !defined $rline;

        $prompt_text = "" if $input_is_multiline;

        # Break if we see the terminator line in multiline input.
        last if $input_is_multiline and $rline eq $terminator;

        # Append the line (with trailing newline) to the response.
        $resp .= $rline;

        if (!$input_is_multiline) {
            $resp = $default if $resp eq q{};
            last;
        }

        # End the line in the response.
        $resp .= $/;
    }

    if (!defined $rline) {
        # Raise an exception for an unexpected EOF.
        PromptEOFException->throw(
            error => "Unexpected EOF.\n", resp => $resp);
    }

    return $resp if (&{$is_valid}($resp));

    # Retry if the response isn't valid
    return $self->_retry_prompt_user($resp);
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

=head1 AUTHOR

Bryan Matsuo (bryan.matsuo@gmail.com)

=head1 BUGS

=over

=back

=head1 COPYRIGHT

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
