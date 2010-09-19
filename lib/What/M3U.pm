#!/usr/bin/env perl

# Use perldoc or option --man to read documentation

# include some core modules
use strict;
use warnings;
use Carp;
use File::Basename;

# include CPAN modules
use Readonly;
use Audio::FLAC::Header;

# include any private modules
# ...

our @EXPORT = qw(
    mkm3u_info
    mkm3u
);

our $VERSION = '0.0_1';

# Subroutine: mkm3u(
#   files => \@flac_paths,
#   TODO: save => $path
# )
# Type: INTERFACE SUB
# Purpose: Given a list of FLAC files for a complete release disc, 
#   make an m3u playlist.
#   The ordering of the playing is determined by the FLAC tags.
#   Inconsistent ordering for a complete release disc (missing track 
#   numbers or duplicate track numbers) will result in croaking.
# Returns: an m3u playlist as a string.
sub mkm3u {
    my %arg = @_;
    my @flac_files = @{$arg{files}};
    my %info;
    for my $flac (@flac_files) {
        $info{$flac} = Audio::FLAC::Header->new($flac);
    }
    return mkm3u_info(info => \%info);
}

# Subroutine: mkm3u_info(
#   info => \%flac_file_info
#   TODO: save => $path
# )
# Type: INTERFACE SUB
# Purpose: 
#   Given a hash mapping file names to Auio::FLAC::Header objects,
#   create an m3u playlist.
#   File basenames are used, so the playlist must be in the same 
#   directory as the music files.
#   The ordering of the playing is determined by the FLAC tags.
#   Inconsistent ordering for a complete release disc (missing track 
#   numbers or duplicate track numbers) will result in croaking.
# Returns: an m3u playlist as a string.
# Returns: 
#   A string representation of the playlist.
sub mkm3u_info {
    my %arg = @_;
    my %file_info = %{$arg{info}};
    my %track_with_num;

    for my $flac (keys %file_info) {
        my $info = $file_info{$flac};
        my $track_number = get_flac_tag($info, 'tracknumber');
        if (!defined $track_number) {
            croak("File $flac has no track number.");
        }
        if (defined $track_with_num{$track_number}) {
            croak("Duplicate track number $track_number found;\n"
                ."$flac\n$track_with_num{$track_number}\n");
        }
        $track_with_num{$track_number} = $flac;
    }

    my @given_track_numbers = sort {$a <=> $b} keys %track_with_num;

    my $last = 0;
    for my $num (@given_track_numbers) {
        my $expected = $last + 1;
        if ($expected != $num) {
            croak("Missing track number $expected.");
        }
        $last = $num;
    }

    my @ordered_tracks 
        = map {$track_with_num{$_}} @given_track_numbers;

    my $m3u = "#EXTM3U\n";
    for my $flac (@ordered_tracks) {
        my $length_in_sec = $file_info{$flac}->{trackTotalLengthSeconds};
        $length_in_sec =~ s/\.\d+\z//xms;
        $m3u .= "#EXTINF:$length_in_sec,"
            . describe_track($file_info{$flac}) . "\n";
        $m3u .= basename($flac) . "\n";
    }

    return $m3u;
}

# Subroutine: describe_track($flac_info)
# Type: INTERNAL UTILITY
# Returns: A string describing the track represented by $flac_info.
sub describe_track {
    my $flac_info = shift;
    my %tag = %{$flac_info->{tags}};
    my $title = get_flac_tag($flac_info,'title');
    my $artist = get_flac_tag($flac_info,'artist');
    my $desc 
        = get_flac_tag($flac_info,'compilation') ? "$artist - $title" 
        : $title;
    return $desc;
}

# Subroutine: get_flac_tag($flac_info,$tag_name)
# Type: INTERNAL UTILITY
# Purpose: Help get flac tags from flac files, 
#   because the can have varying case.
# Returns: 
#   The value of the tag, or an undefined value otherwise.
sub get_flac_tag {
    my $flac_info = shift;
    my $tag_name = shift;
    my %tag = %{$flac_info->{tags}};
    return $tag{uc $tag_name} || $tag{lc $tag_name};
}

__END__

=head1 NAME

M3U.pm
-- Create and M3U playlists.

=head1 VERSION

Version 0.0_1
Originally created on 09/18/10 23:46:19

=head1 DESCRIPTION

=head1 AUTHOR

Bryan Matsuo (bryan.matsuo@gmail.com)

=head1 BUGS

=over

=back

=head1 COPYRIGHT
