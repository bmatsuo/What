package What::Converter::MP3;

use strict;
use warnings;
use Carp;
use File::Basename;
use What::Utils;
use What::Subsystem;
use What::Format;
use MP3::Tag;

require Exporter;
use AutoLoader qw(AUTOLOAD);

push our @ISA, qw(Exporter);

our @EXPORT_OK = ( );

our @EXPORT = qw(
);

our $VERSION = '0.0_1';

use Moose;
extends 'What::Converter::Base';

has 'bitrate' => (isa => 'Str', is => 'rw', required => 1);

my %lame_tag = (
    ARTIST => '--ta',
    ALBUM => '--tl',
    TITLE => '--tt',
    DATE => '--ty',
    #GENRE => '--tg',
    COMMENT => '--tc',
    # The rest of the tags need to be handled as the were...
    #TRACKNUMBER => '--tn',
    #DISCNUMBER => '--disc',
    #COMPILATION => '--compilation',
    #COMPOSER => '--writer',
);

# Subroutine: is_valid_bitrate($bitrate)
# Type: INTERNAL UTILITY
# Purpose: Determine if a given bitrate is valid (320, V0, or V2).
# Returns: A true context if the given bitrate string is valid. False otherwise.
sub is_valid_bitrate {
    my $self = shift;
    my $bitrate = shift;
    return 1 if (format_extension($bitrate) eq 'mp3');
    return;
}

sub image_options { 
    my $self = shift; 
    my $img = $self->temp_img_path;
    my $img_size = -s $img;
    if ($img_size < 128 * (1 << 10)) {
        return ('--ti', $self->temp_img_path) 
    }
    return ();
}
sub can_embed_img { return 1 }
sub format_descriptor { my $self = shift; return uc $self->bitrate }
sub ext { return 'mp3'; }
sub needs_wav { return 1; }
sub program { return "lame"; }
sub program_description { return `lame --version | head -n 1`; }

#TODO: Fill in the next three subroutines!
sub audio_quality_options { 
    my $self = shift;

    my @opts = qw{--replaygain-accurate};

    my $bitrate = $self->bitrate;

    if ($bitrate eq 'V0') {
        push @opts, qw{-V0 --vbr-new};
    }
    elsif ($bitrate eq 'V2') {
        push @opts, qw{-V2 --vbr-new};
    }
    elsif ($bitrate eq '320') {
        push @opts, qw{--cbr -b320 -h};
    }

    return @opts;
}

sub tag_options {
    my $self = shift;

    my @opts = qw(--add-id3v2);

    for my $tag (keys %lame_tag) {
        my $val = $self->flac->tag($tag);
        next if !defined $val;
        push @opts, $lame_tag{$tag}, $val if $val =~ m/./xms;
    }

    return @opts; 
}

# Subroutine: $converter->other_options(
#   input => $lossles_path,
# )
sub other_options { 
    my $self = shift;
    return (qw{--quiet --nohist}, $self->output_path); 
}

sub copy_remaining_tags {
    my $self = shift;
    my  ($flac_info_ref, $mp3_path) 
        = ($self->flac->head, $self->output_path);

    my $mp3 = MP3::Tag->new($mp3_path);

    $mp3->get_tags;

    my %id3v2_tag = (
        'COMPILATION' => 'TCMP',
        'ISRC' => 'TSRC',
        'GENRE' => 'TCON',       # THESE CAN HAVE NONASCII CHARS
        'ALBUMARTIST' => 'TPE2', # THESE CAN HAVE NONASCII CHARS
        'COMPOSER'    => 'TCOM', # THESE CAN HAVE NONASCII CHARS

        #'ALBUM' => 'TALB', # Handled in MP3 Creation
        #'ARTIST'=> 'TPE1', # Handled in MP3 Creation
        #'TITLE' => 'TIT2', # Handled in MP3 Creation
        #'DATE' => 'TDRC', # Handled in MP3 Creation
        # HANDLE TRACKNUMBER SPECIALLY,
        #'TRACKNUMBER' => 'TRCK',
        #'TRACKTOTAL' => 'TRCK',
        # HANDLE DISCNUMBER SPECIALLY,
        #'DISCNUMBER'  => 'TPOS',
        #'DISCTOTAL'   => 'TPOS',
        #'COMMENT' => 'COMM',

        # Ignore the vendor tag,
        #'VENDOR' => 'TENC',
    );

    my %song_tag = %{$flac_info_ref->{tags}};

    # Set ID3v2 tags;
    if (exists $mp3->{ID3v2}) {
        for my $flac_tag (keys %song_tag) {
            my $tag_val = $song_tag{$flac_tag};
            my $id3_tag = $id3v2_tag{uc $flac_tag};
            if (defined $tag_val and defined $id3_tag) {
                #print {\*STDERR} "\nSetting $flac_tag: $tag_val";
                $mp3->set_id3v2_frame($id3_tag, $tag_val);
            }
        }
        #print {\*STDERR} "\n";
        my ($t_num, $t_tot) 
            = ($song_tag{'TRACKNUMBER'}, $song_tag{'TRACKTOTAL'});
        my ($d_num, $d_tot) 
            = ($song_tag{'DISCNUMBER'}, $song_tag{'DISCTOTAL'});
        # Compute track number tag value, if it exists.
        my $t_val 
            = defined $t_num && defined $t_tot  ? "$t_num/$t_tot"
                : defined $t_num                ? $t_num
                :                               "";
        # Compute the disc number tag value, if it exists.
        my $d_val 
            = defined $d_num && defined $d_tot  ? "$d_num/$d_tot"
                : defined $d_num                ? $d_num
                :                               "";
        $mp3->set_id3v2_frame('TRCK', $t_val) if ($t_val =~ m/.+/xms);
        $mp3->set_id3v2_frame('TPOS', $d_val) if ($d_val =~ m/.+/xms);
        $mp3->{ID3v2}->write_tag();
    }

    # Set ID3v1 tags.
    if (exists $mp3->{ID3v1}) {
        #if (defined $song_tag{'COMMENT'}) {
        #    $mp3->{ID3v1}->comment(utf8::decode($song_tag{'COMMENT'}));
        #}
        #if (defined $song_tag{'TITLE'}) {
        #    $mp3->{ID3v1}->title(utf8::decode($song_tag{'TITLE'}));
        #}
        #if (defined $song_tag{'ARTIST'}) {
        #    $mp3->{ID3v1}->artist(utf8::decode($song_tag{'ARTIST'}));
        #}
        #if (defined $song_tag{'ALBUM'}) {
        #    $mp3->{ID3v1}->album(utf8::decode($song_tag{'ALBUM'}));
        #}
        #if (defined $song_tag{'DATE'}) {
        #    $mp3->{ID3v1}->year(utf8::decode($song_tag{'DATE'}));
        #}
        #if (defined $song_tag{'TRACK'}) {
        #    $mp3->{ID3v1}->track(utf8::decode($song_tag{'TRACK'}));
        #}
        # Don't deal with ID3v1 genre crap.
        #if (defined $song_tag{'GENRE'}) {
        #    $mp3->{ID3v1}->genre(utf8::decode($song_tag{'GENRE'}));
        #}
        #$mp3->{ID3v1}->write_tag();
    }
    return;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What::Converter::MP3

=head1 ABSTRACT

This class can be used to convert flac files to MP3 format.
This may turn into a base class for different bitrate converters.

=head1 SYNOPSIS

    my $mp3_converter = What::Converter::MP3->new();
    $mp3_converter->convert(
        flac => "/rips/foo.flac",
        flac => "/rips/foo.wav",
        output => "/rips/foo.mp3");

=head1 SEE ALSO

What::Converter::Base
What::Converter::Ogg
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
