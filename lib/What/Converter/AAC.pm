package What::Converter::Ogg;

use 5.008009;
use strict;
use warnings;
use Carp;
use File::Basename;
use What::Utils;
use What::Subsystem;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT_OK = ( );

our @EXPORT = qw(
);

our $VERSION = '0.0_1';

use Moose;
extends 'What::Converter::base';

# Subroutine: $converter->needs_wav()
# Type: INSTANCE METHOD
# Returns: 
#   A true boolean context if the converter needs a WAVE audio file.
sub needs_wav { return 1; }

# Subroutine: $converter->program()
# Type: INSTANCE METHOD
# Returns: The converting program used be the coverter.
sub program { return "faac"; }

# Subroutine: $converter->program_description()
# Type: INSTANCE METHOD
# Returns: A string naming the program and version number.
sub program_description { return `faac --help | head -n 2 | tail -n 1`; }

# Subroutine: $converter->audio_quality_options()
# Type: INSTANCE METHOD
# Returns: 
#   A list of command line options used that control quality (bitrate).
sub audio_quality_options { return (); }

# Subroutine: $converter->tag_options(flac => $flac_path)
# Type: INSTANCE METHOD
# Returns: 
#   A list of command line options used that set tags.
sub tag_options { return (); }

# Subroutine: $converter->other_options(
#   input => $lossles_path,
#   flac => $flac_path,
#   output => $lossy_path,
# )
# Type: INSTANCE METHOD
# Purpose:
#   Some options, such as silencing, may not fit into other categories, 
#   so they can go here.
# Returns: 
#   A list of other command line options used in converting.
sub options { return (); }

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What::Converter::AAC

=head1 ABSTRACT

This class can be used to convert flac files to AAC format.

=head1 SYNOPSIS

    my $aac_converter = What::Converter::AAC->new();
    $aac_converter->convert(
        flac => "/rips/foo.flac",
        wav => "/rips/flac.wav",
        output => "/rips/foo.mp3");

=head1 SEE ALSO

What::Converter::Base
What::Converter::Ogg
What::Converter::MP3

=head1 AUTHOR

Bryan Matsuo, <bryan.matsuo@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Bryan Matsuo

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
