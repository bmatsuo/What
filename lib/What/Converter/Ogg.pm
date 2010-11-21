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

push our @ISA, qw(Exporter);

our @EXPORT_OK = ( );

our @EXPORT = qw(
);

our $VERSION = '0.0_1';

use Moose;
extends 'What::Converter::Base';

sub ext {return 'ogg';}
sub needs_wav { return 0; }
sub program { return "oggenc"; }
sub program_description { return `oggenc --version`; }

sub audio_quality_options { return ('-q', '8'); }

# Tags are taken out of the FLAC when vorbis-tools has FLAC support.
sub tag_options { return (); }

# Subroutine: $converter->other_options(
#   input => $lossles_path,
# )
sub other_options { 
    my $self = shift;
    # Silence oggenc and set the output path.
    return ('-Q', '-o', $self->output_path); 
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What::Converter::Ogg

=head1 ABSTRACT

This class can be used to convert flac files to Ogg Vorbis format.

=head1 SYNOPSIS

    my $ogg_converter = What::Converter::Ogg->new();
    $ogg_converter->convert(
        flac => "/rips/foo.flac",
        output => "/rips/foo.ogg");

=head1 SEE ALSO

What::Converter::Base
What::Converter::MP3
What::Converter::AAC

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
