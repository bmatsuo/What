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
    'FileDoesNotExistError', 
    'FileExistsError',
    'FilePerissionError',
    'FileFormatException',
    'IllegalCharacterError' => {
        fields => [qw{characters}],
    },
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
