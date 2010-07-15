#!/usr/bin/env perl
package What::Prompt;

# Use perldoc to read documentation

# include some core modules
use strict;
use warnings;

# include CPAN modules
use Readonly;
use Term::ReadLine;
use Class::InsideOut qw{:std};#:std = id private public readonly register

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


############
# Attributes
############

public text         => my %text_of, {
    set_hook => 
        sub { m/\S/ or die("can't use blank prompt text.") },
};
public is_multiline => my %multiline_input_for;
public terminator  => my %terminator_of, {
    set_hook => sub { 
        (not /\t|\r|\n/ and /^\S(?:.*\S)?$/) 
            or die("can't have any of '\\t','\\r','\\n',"
                ."or start/end in whitespace")},
};
public validator   => my %validator_of, {
    set_hook => sub {"CODE" eq ref $_[0] or die('not given code.')}};
private term        => my %readline_of;

my $prompt_count = 0;
my $def_validator = \&{sub {return 1}};
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

    my $term;
    eval { $term = Term::ReadLine->new("Prompt $prompt_count") };

    if (!$@ eq q{}) {
        PromptException(error=>"Failed to create terminal $@")
    }

    my $self = register($class);
    $prompt_count += 1;

    $text_of{id $self} = $text;
    $multiline_input_for{id $self} = $is_multiline;
    $terminator_of{id $self} = $terminator;
    $validator_of{id $self} = $validator;
    $readline_of{id $self} = $term;

    return $self;
}

# Subroutine: $prompt->reset_validator()
# Type: INSTANCE METHOD
# Purpose: 
#   Reset the validator to one that accepts all input.
# Returns: 
#   Nothing
sub reset_validator {
    my $self = shift;
    $self->validator(sub {1});
    return;
}

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
    my $text = $text_of{id $self};
    my $input_is_multiline = $multiline_input_for{id $self};
    my $terminator = $terminator_of{id $self};
    my $is_valid = $validator_of{id $self};
    my $term = $readline_of{id $self};
    my $resp = "";

    my $terminate_help 
        = join q{}, 
            qq{(stop input with a line "$terminator<Enter>")}, ;

    my $prompt_text 
        = $text.($input_is_multiline ? "$/$terminate_help$/" : q{});

    my $line_count = 0;

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

        last if !$input_is_multiline;

        $resp .= $/;
    }

    if (!defined $rline) {
        # Raise an exception for an unexpected EOF.
        PromptEOFException->throw(
            error=>'unexpected EOF', resp => $resp);
    }

    return $resp if (&{$is_valid}($resp));

    # Retry if the response isn't valid
    return $self->_retry_prompt_user($resp);
}

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
