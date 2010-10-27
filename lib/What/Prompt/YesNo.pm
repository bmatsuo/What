#!/usr/bin/env perl
package What::Prompt::YesNo;

# Use perldoc to read documentation

# include some core modules
use strict;
use warnings;

# include CPAN modules
use Readonly;
our $VERSION = '0.0_1';

use Exception::Class (
    'NonBooleanDefault'
);

# include any private modules
use What;
use Moose;
extends 'What::Prompt::Base';

has 'default'
    =>(isa => 'Str', is => 'rw', default => 'yes', trigger => \&_default_set_);
has 'question'
    =>(isa => 'Str', is => 'rw', required => '1');


sub _default_set_ {
    my ($self, $new_def, $old_def) = @_;
    if (!$new_def =~ /\A (?: yes | no ) \z/ixms) {
        NonBooleanDefault->throw(
            error => "'default' attribute $new_def is not 'yes'/'no'.");
    }
}

sub text {
    my $self = shift;
    my $def_is_yes = $self->default =~ /yes/ixms;
    return $self->question . ($def_is_yes ? '[Yn]' : '[yN]');
}

my $_v_sub_ = sub {
    my $r = shift; 
    my $patt = qr{
        \A (?: (?: y(?:es)? ) | (?: no? ) )? \z}ixms;
    return $r =~ $patt; 
};

sub validator {
    my $self = shift;
    return $_v_sub_;
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
