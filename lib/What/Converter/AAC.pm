package What::Converter::AAC;

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

my %aac_tag = (
    ARTIST => '--artist',
    TITLE => '--title',
    DATE => '--year',
    TRACKNUMBER => '--track',
    DISCNUMBER => '--disc',
    COMPOSER => '--writer',
    GENRE => '--genre',
    ALBUM => '--album',
    COMPILATION => '--compilation',
    COMMENT => '--comment',
    # forget --cover-art for now,
);

sub ext { return 'm4a'; }
sub needs_wav { return 0; }
sub program { return "faac"; }
sub program_description { return `faac --help | head -n 2 | tail -n 1`; }
sub audio_quality_options { return qw{-c 22050 -b 256}; }
# Fill in these options
sub tag_options { 
    my $self = shift;
    my @opts;
    for my $t (keys %aac_tag) {
        my $v = $self->flac->tag($t);
        next if (!defined $v);
        push @opts, $aac_tag{$t}, $v if $v =~ m/./xms;
    }
    return @opts; 
}
# Subroutine: $converter->other_options(
#   input => $lossles_path,
# )
sub other_options { 
    my $self = shift;
    my %arg = @_;
    if (!defined $self->output_path) {
        croak(".m4a output path not specified.");
    }
    return ('-w', '-o', $self->output_path); 
}

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
