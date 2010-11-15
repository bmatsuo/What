package What::Release;

use strict;
use warnings;
use Carp;
use File::Basename;
use File::Glob 'bsd_glob';

use What::Utils qw{:all};
use What::Format;
use What::Subsystem;
use What::WhatRC;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.0_3';

my %def_arg = ( 
    rip_root => whatrc->upload_root,
    artist  => "",
    title   => "",
    year    => "",
    discs   => 1,
    label   => "",
    desc    => "",);

# Subroutine: 
#   What::Release->new(
#       [rip_root=> $rip_root,]
#       artist  => $artist,
#       title   => $title,
#       year    => $year,
#       label   => $label,
#       desc    => $description,);
# Type: CLASS METHOD
# Purpose: Create a What::Release object.
#   The constructor requires arguments 'artist', 'title', and 'year'.
#   'label' and 'desc' are optional arguments.
#   When 'rip_root' is not given, then the 'upload_root' config value of
#   '~/.whatrc' is used.
# Returns:
#   New What::Release object.
sub new {
    my $class = shift;
    my %arg = @_;
    %arg = (%def_arg, %arg);

    my $rip_root = $arg{rip_root};

    my @rip_root = bsd_glob(glob_safe($rip_root)."/");

    croak("'rip_root' field must be a path to an existing directory.")
        if !@rip_root;

    croak("'artist' field must be a non-empty string")
        if $arg{artist} =~ m/\A\z/xms;
    croak("'title' field must be a non-empty string")
        if $arg{title} =~ m/\A\z/xms;
    croak("'year' field must be a non-empty string")
        if $arg{year} =~ m/\A\z/xms;

    my $self = {};

    for my $field (keys %def_arg) { $self->{$field} = $arg{$field} };

    bless $self, $class;
    return $self;
}

### INSTANCE METHOD
# Subroutine: dup
# Usage: $release->dup()
# Purpose: Create a duplicate release object.
# Returns: A new What::Release oject.
# Throws: Nothing
sub dup {
    my $self = shift;
    # TODO: Values may still be tied together (dangerous).
    return What::Release->new(%{$self});
}

### INSTANCE METHOD
# Subroutine: rerooted
# Usage: $self->rerooted( $new_root )
# Purpose: 
#   Make a new release object rooted at a different directory, 
#   but otherwise identical.
# Returns: A new What::Release object.
# Throws: Nothing
sub rerooted {
    my $self = shift;
    my ($new_root) = @_;
    my $new_obj = $self->dup();
    $new_obj->{rip_root} = $new_root;
    return $new_obj;
}

### INSTANCE METHOD
# Subroutine: exists
# Usage: $self->exists(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub exists {
    my $self = shift;

    return -d $self->dir();
}

# Subroutine: name()
# Type: INSTANCE METHOD
# Purpose: Compute the name of a release.
# Returns: String containing the name of the release.
sub name() {
    my $self = shift;
    my $name = "$self->{artist} - $self->{title} ($self->{year})";
    return $name;
}

# Subroutine: $release->artist_dir()
# Type: INSTANCE METHOD
# Purpose: 
#   Compute the release's root directory, given the rip root directory.
# Returns: A path to the release's root directory.
sub artist_dir() {
    my $self = shift;

    my $name = $self->name();

    my $artist_dir = "$self->{rip_root}/$self->{artist}";

    return $artist_dir;
}

# Subroutine: $release->dir()
# Type: INSTANCE METHOD
# Purpose: 
#   Compute the release's root directory, given the rip root directory.
# Returns: A path to the release's root directory.
sub dir() {
    my $self = shift;

    my $name = $self->name();

    my $artist_dir = $self->artist_dir();

    my $release_root = "$artist_dir/$name";

    return $release_root;
}

# Subroutine: $release->format_dir( $format)
# Type: INSTANCE METHOD
# Purpose: 
#   Compute the release's root directory, given the rip root directory.
# Returns: A path to the release's root directory.
sub format_dir {
    my $self = shift;

    my $format = shift;

    # Fix case of $format, and identify type.
    my $format_ext = format_extension($format);
    my $format_print = format_normalized($format);
    croak ("Unknown format $format_print.") if $format_ext eq q{};

    my $release_name = $self->name();
    my $release_root = $self->dir();

    my $format_dir = "$release_root/$release_name [$format_print]";

    return $format_dir;
}

# Subroutine: $release->find_audio_files($format)
# Type: INSTANCE METHOD
# Purpose: 
#   Find all audio files in $release's $format dir.
# Returns: A list of paths to audio files.
# Exceptions: Croaks when the $format dir of $release does not exist.
sub find_audio_files {
    my $self = shift;
    my ($format) = @_;

    # Fix case of $format, and identify type.
    my $format_ext = format_extension($format);
    my $format_print = format_normalized($format);
    croak ("Unknown format $format_print.") if $format_ext eq q{};

    # Find the format directory.
    my $format_dir = $self->format_dir($format);
    croak ("Can't find any $format_print release.") 
        if !-e $format_dir;
    croak ("Non-directory in place of $format_print release.") 
        if !-d $format_dir;

    # Find all of the audio files contained in the format directory.
    my @format_files = find_hierarchy($format_dir);
    my @audio_files = grep {m/\.$format_ext\z/xms} @format_files;
    croak ("Missing $format_print files in $format_print release dir.") 
        if (!@audio_files);

    return @audio_files;
}

# Subroutine: $release->format_disc_dirs($upload_root, $format);
# Type: INSTANCE METHOD
# Purpose: Find all disc directories in a rip directory.
# Returns: 
#   A list of disc directories (containing music) for a given format.
sub format_disc_dirs {
    my $self = shift;
    my ($format) = @_;

    # Fix case of $format, and identify type.
    my $format_ext = format_extension($format);
    my $format_print = format_normalized($format);
    croak ("Unknown format $format_print.") if $format_ext eq q{};

    # Find all the audio files in the release's format dir.
    my @audio_files = $self->find_audio_files($format);

    # Find directories containing found audio files, and return.
    my @music_dirs_w_repeats = map {dirname($_)} @audio_files;
    my %is_music_dir = (map {($_ => 1)} @music_dirs_w_repeats);
    my @music_dirs = keys %is_music_dir;
    return @music_dirs if @music_dirs; # This should always happen

    # Reaching 'return' means at least one directory should be found.
    croak ("For some reason, no disc directory could be found.");
}

# Subroutine: $release->scaffold($format)
# Type: INSTANCE METHOD
# Purpose: 
#   Create hierarchy stucture for given release format at a specified
#   root directory.
# Returns:
#   The path to the format release directory.
sub scaffold {
    my $self = shift;
    my ($format) = @_;
    my $root = $self->{rip_root};

    croak("Root directory not defined.") if !defined $root;
    croak("Root '$root' does not exist.") if !-e $root;
    croak("Root '$root' is not a directory.") if !-d $root;
    croak("Format '$format' is not recognized.") 
        if !format_is_accepted($format);

    my $fdir = $self->format_dir($root,$format);

    create_directory($fdir);

    return $fdir;
}

# Subroutine: $release->copy_format_dir($format, $dest)
# Type: INSTANCE METHOD
# Purpose: Copy a format release into a given directory.
# Returns: Nothing
sub copy_format_dir {
    my $self = shift;
    my ($format, $dest) = @_;

    if (!-d $dest) {
        croak("Can't copy to non-directory '$dest'.\n");
    }

    my $fdir = $self->format_dir($format);

    subsystem(cmd => ['cp', $fdir, $dest]) == 0
        or croak("Couldn't copy format directory.\n$?\n");

    return;
}

# Subroutine: $release->copy_music_into_hierarchy($format, $new_root)
# Type: INSTANCE METHOD
# Purpose: 
#   Copy the music files of one format into another hierarchy.
#   This can be used for importing into a music library.
#   Non-music files (logs, cues, playlists, nfo, text files,...) are not copied.
# Returns: Nothing
sub copy_music_into_hierarchy {
    my $self = shift;
    my ($format, $new_root);
    my $root = $self->{rip_root};
    my $fdir = $self->format_dir($format);
    my @disc_dirs = $self->format_disc_dirs($format);
    my $reroot = $self->rerooted($new_root);
    my $target = $reroot->scaffold($format);
    my $extension = format_extension($format);

    for my $d (@disc_dirs) {
        my $rel_disc_path = substr $d, 0, length ($fdir) + 1, q{};
        my $target_disc_dir = $target;
        if (!$d eq $fdir) {
            $target_disc_dir .= "/$rel_disc_path";
            create_directory($_);
        }
        my @songs = find_file_pattern("*.$extension", $d);
        if (!@songs) {
            croak("No '.$extension' songs found in supposed disc directory $d.\n");
        }
        subsystem(cmd => ['cp', @songs, $target_disc_dir]) == 0
            or croak("Couldn't copy songs to $target_disc_dir.\n$?\n");
    }

    return;
}

# Subroutine: $release->format_torrent($format)
# Type: INSTANCE METHOD
# Returns: The path to the torrent file for a given format.
sub format_torrent {
    my $self = shift;
    my ($f) = @_;
    my $fdir = $self->format_dir($f);
    my $torrent = "$fdir.torrent";
    return $torrent;
}


# Subroutine: $release->delete_format($format)
# Type: INSTANCE METHOD
# Purpose: Delete a specified release format.
# Returns: Nothing
sub delete_format {
    my $self = shift;
    my ($format) = @_;

    my $fdir = $self->format_dir($format);
    if (!-e $fdir) {
        croak("$format release does not exist.");
    }
    subsystem(cmd => ['rm', '-r', $fdir]) == 0
        or croak("Couldn't remove format release '$fdir'.\n$?\n");

    my $torrent = $self->format_torrent($format);
    if (-e $torrent) {
        subsystem(cmd => ['rm', '-r', $torrent]) == 0
            or croak("Couldn't remove torrent '$fdir'.\n$?\n");
    }
    return;
}

# Subroutine: $release->delete_release()
# Type: INSTANCE METHOD
# Purpose: Delete the release directory.
sub delete_release {
    my $self = shift;
    my $rdir = $self->dir();
    subsystem(cmd => ['rm', '-r', $rdir]) == 0
        or croak("Couldn't remove release directory '$rdir'.\n$?\n");
    return;
}

# Subroutine: $release->delete_artist()
# Type: INSTANCE METHOD
# Purpose: Delete the release's artist directory. Use with caution.
sub delete_artist {
    my $self = shift;
    my $adir = $self->artist_dir();
    subsystem(cmd => ['rm', '-r', $adir]) == 0
        or croak("Couldn't remove artist directory '$adir'.\n$?\n");
    return;
}


# Subroutine: $release->existing_formats()
# Type: INSTANCE METHOD
# Purpose: 
# Returns: Nothing
sub existing_formats {
    my $self = shift;
    my $rdir = $self->dir();
    my @formats;
    for my $subdir (find_subdirs($rdir)) {
        my $name = basename($subdir);
        if ($name =~ m/ \[ ([A-Z0-9]+) \] \z/xms) {
            my $fname = $1;
            if (my $f = format_is_accepted($fname)) {
                push @formats, $f;
            }
            else {
                croak("Found unrecognized format name $fname.\n");
            }
        }
        else {
            croak("Subdirectory doesn't look like a format release '$name'.\n");
        }
    }

    return @formats;
}

# Subroutine: $release->artist_releases()
# Type: INSTANCE METHOD
# Returns: A list of all releases by the artist.
sub artist_releases {
    my $self = shift;
    my $adir = $self->artist_dir();
    return find_subdirs($adir);
}


1;
__END__
=head1 NAME

What::Release - A simple class to access the upload hierarchy of releases.

=head1 SYNOPSIS

  use What::Release;

=head1 ABSTRACT

A What::Release object contains artist, title, and year information for a release.
It has instance methods for accessing the releases in the upload hierarchy.
Any program wanting to access the upload hierarchy should include What::Release.

=head2 EXPORT

None by default.

=head1 SEE ALSO

What::Format, What::Utils

mkrelease, release-flac-convert, release-mktorrent, release-scaffold

=head1 AUTHOR

Bryan Matsuo, E<lt>bryan.matsuo@gmail.comE<gt>

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
