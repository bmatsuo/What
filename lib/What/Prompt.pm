#!/usr/bin/env perl
package What::Prompt;

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
        fiends  => [qw{resp}],
        description => 
            'Thrown if unexpected EOFs are read. Has a partial response.',
    },
);

# Use perldoc or option --man to read documentation

# include some core modules
use strict;
use warnings;

# include CPAN modules
use Readonly;
# :std = id private public readonly register
use Class::InsideOut qw{ :std };

# include any private modules
use What;

############
# Attributes
############

private text        => my %text_of;
public is_multiline => my %multiline_input_for;
private terminator  => my %terminator_of;
private validator   => my %validator_of;

my $def_validator = sub {return 1};
my $def_attr_ref = {
    text            => "Please enter input:",
    is_multiline    => 0,
    terminator      => '.',
    validator       => $def_validator,
};

# Subroutine: 
#   What::Prompt->new(
#       {   text => $prompt_string,
#           validator       => $validation_sub
#           is_multiline    => $is_multiline,
#           terminator      => $term_string,})
# Type: CLASS METHOD
# Purpose: 
#   What::Prompt constructor method.
#   None of the properties are strictly necessary.
#   The validator property be a subroutine reference that returns a
#   boolean result when passed a single prompt response string.
#   If is_multiline is given as a true value, then the prompt will accept
#   multiple lines of input until a line consisting only of $term_string
#   is given. The default terminator string is "." .
# Raises:
#   ArgumentException if the text is missing.
#   PromptTextException if the text is empty.
#   ValueException if terminate is equal to undef or is not a string.
# Returns: 
#   The newly created What::Prompt object.
sub new {
    my $class = shift;

    my $arg_ref = shift (@_) || {};

    if (!defined $arg_ref || !'HASH' eq ref $arg_ref) {
        # Raise an exception when not given arguments, 
        #   or if arguments aren't contained in a hash reference.
        my $msg = join "",
        'first argument required to be a hash ref; ',
        'given ', ref $arg_ref,;
        ArgumentException->throw(error => $msg);
    }

    my %args = (%$def_attr_ref, %$arg_ref);

    my $text = $args{text};
    my $is_multiline = $args{is_multiline};
    my $terminator = $args{terminator};
    my $validator = $args{validator};

    if (!defined $text || $text =~ m/\A\s*\z/xms) {
        # Raise an exceptino when the prompt text is not given,
        #   or appears to be blank.
        my $msg = join q{},
        'prompt text must be given as a string with at least ',
        'one non-whitespace character in it.',;
        PromptTextException->throw(text => $text, error => $msg);
    }

    if (ref $terminator) {
        my $msg = "terminator must be a string not a ".ref $terminator;
        ValueException->throw(error=>$msg);
    }

    if (!"CODE" eq ref $validator) {
        my $msg 
            = "validator must be a subroutine ref; got "
            . ref $validator;
        ValueException->throw(error=>$msg);
    }

    my $self = register($class);

    $text_of{id $self} = $text;
    $multiline_input_for{id $self} = $is_multiline;
    $terminator_of{id $self} = $terminator;
    $validator_of{id $self} = $validator;

    return $self;
}

# Subroutine: $prompt->_retry_prompt($previous_response)
# Type: INTERNAL UTILITY
# Purpose: 
#   Attempt to reissue the same prompt due to a misunderstoop response.
# Returns: 
#   The reissued prompt's user response
sub _retry_prompt {
    my $self = shift;
    my $resp = shift;
    print "I couldn't understand '$resp'.\n";
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
    my $text = $text_of{id $self};
    my $input_is_multiline = $multiline_input_for{id $self};
    my $terminator = $terminator_of{id $self};
    my $is_valid = $validator_of{id $self};
    my $resp = "";

    my $terminate_help 
        = join q{}, 
            qq{(stop input with a line "$terminator<Enter>")}, ;

    print $text;
    print $terminate_help if $input_is_multiline;

    # Read user response.
    my $rline;
    while ($rline = <STDIN>) {
        # Make a chomped copy of the line.
        my $chomp_line = $rline;
        $chomp_line =~ s/\r?\n?\z//xms;

        # Break if we see the terminator line in multiline input.
        last if $input_is_multiline and $chomp_line eq $terminator;

        # Append the line (with trailing newline) to the response.
        $resp .= $rline;
    }

    if (!defined $rline) {
        # Raise an exception for an unexpected EOF.
        PromptEOFException->throw(
            error=>'unexpected EOF', resp => $resp);
    }

    # Check that input is valid.
    if ($is_valid->($resp)) {
        return $resp
    }

    # The validator couldn't understand the response. Retry.
    return $self->_retry_prompt_user();
}

__END__

=head1 NAME

Prompt.pm
-- Module for command-line prompting in What scripts.

=head1 VERSION

Version 0.0_2
Originally created on 07/14/10 18:38:01

=head1 DESCRIPTION

This Module contains the What::Prompt class of object. It can handle
prompting the user through STDOUT and reading a response via STDIN. It
can also handle automatic retrying of invalid responses.

=head1 EXAMPLES

    use What::Prompt;

    # Check if a number is an integer.
    sub is_int { return $_[0] =~ m/^-?\d+$/ }

    # Create a prompt asking the user for a number.
    my $p = What::Prompt->new({
        text => "Enter a number:", 
        validator => is_int ,});

    # Execute multiple prompts.
    my $x = $p->prompt_user();
    my $y = $p->prompt_user();
    my $prod = $x * $y;

    # Print the product of the numbers read from the user.
    print "The first number times the second is $prod.\n";

=head1 AUTHOR

Bryan Matsuo (bryan.matsuo@gmail.com)

=head1 BUGS

=over

=back

=head1 COPYRIGHT
