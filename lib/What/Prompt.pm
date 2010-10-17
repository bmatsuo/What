#!/usr/bin/env perl
package What::Prompt;

# Use perldoc to read documentation

# include some core modules
use strict;
use warnings;
use IO::Handle;

our $VERSION = '0.0_3';

use Moose;
extends 'What::Prompt::Base';

my $prompt_count = 0;
has 'text'
    => (isa => 'Str', is => 'rw', default => q{Please enter text:});
has 'validator'
    => (isa => 'CodeRef', is => 'rw', default => sub { return sub {1} });

# Subroutine: $prompt->reset_validator()
# Type: INSTANCE METH
# Purpose: 
#   Reset the validator to one that accepts all input.
# Returns: 
#   Nothing
sub reset_validator {
    my $self = shift;
    $self->validator(sub {1});
    return;
}

1

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
