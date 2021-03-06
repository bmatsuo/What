#!/usr/bin/env perl
# Use perldoc or option --man to read documentation
package What::Exceptions::Common;
use strict;
use warnings;

our $VERSION = "00.00_01";
# Originally created on 12/12/10 00:02:02

use Exception::Class (
    'Error',
    'UnknownError',
    'ValueError', 'TypeError',
    'IOError',
    'FileDoesNotExistError' => {
        isa => 'IOError'
    }, 
    'FileExistsError' => {
        isa => 'IOError'
    },
    'FilePerissionError' => {
        isa => 'IOError'
    },
    'FileFormatException',
    'UnknownFormatError' => {
        fields => [qw{name}],
    },
    'IllegalCharacterError' => {
        fields => [qw{characters}],
    },
    'ServerResponseError',
);

return 1;
__END__

=head1 NAME

What::Exceptions::Common - Exceptions common to many What libraries.

=head1 VERSION

Version 00.00_01

=head1 DESCRIPTION

Exceptions common to many What libraries.

=head1 AUTHOR

Bryan Matsuo [bryan.matsuo@gmail.com]

=head1 BUGS

=over

=back

=head1 COPYRIGHT & LICENCE

(c) Bryan Matsuo [bryan.matsuo@gmail.com]
