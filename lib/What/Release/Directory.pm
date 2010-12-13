#!/usr/bin/env perl
# Use perldoc or option --man to read documentation
# Originally created on 12/11/10 23:37:18
package What::Release::Directory;
use strict;
use warnings;
use File::Basename;
use What::WhatRC;
use What::Format;
use What::Utils qw{:files :dirs};
use What::Subsystem;
use What::Exceptions::Common;

require Exporter;
use AutoLoader qw(AUTOLOAD);
push our @ISA, 'Exporter';

# If you do not need this, 
#   moving things directly into @EXPORT or @EXPORT_OK will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw{
    scan_release_dir
    scan_rip_dir
};

use Exception::Class (
    'NoAudioError', 
    'MultipleFormatsError', 'UnknownFormatError',
    'UnexpectedFile',
    'NestedDiscError');

use Moose;

has 'name' => (isa => 'Str', is => 'rw', );
has 'path' => (isa => 'Str', is => 'rw', required => 1);
has 'nfo' => (isa => 'Str', is => 'rw');
has 'subdirs' => (isa => 'ArrayRef[What::Release::Directory]',
        is => 'rw', default => sub {[]});
has 'logs' => (isa => 'ArrayRef[Str]', is => 'rw', default => sub {[]});
has 'cues' => (isa => 'ArrayRef[Str]', is => 'rw', default => sub {[]});
has 'songs' => (isa => 'ArrayRef[Str]', is => 'rw', default => sub {[]});
has 'images' => (isa => 'ArrayRef[Str]', is => 'rw', default => sub {[]});
has 'm3us' => (isa => 'ArrayRef[Str]', is => 'rw', default => sub {[]});
has 'other_files' => (isa => 'ArrayRef[Str]', is => 'rw', default => sub {[]});
has 'hidden_files' => (isa => 'ArrayRef[Str]', is => 'rw', default => sub {[]});
has 'is_disc' => (isa => 'Bool', is => 'rw', default => 0);
has 'is_root' => (isa => 'Bool', is => 'rw', default => 0);

### INSTANCE METHOD
# Subroutine: subdirs_rec
# Usage: $dir->subdirs_rec( $filter )
# Purpose: 
# Returns: 
#   A list of all contained directories s.t. $filter->($dir) is true.
#   A list of all contained directories otherwise.
# Throws: Nothing
sub subdirs_rec {
    my $self = shift;
    my ($filter) = @_;
    $filter = $filter || sub { 1 };
    my @all_subdirs;
    my @subdirs = @{$self->subdirs};
    for my $d (@subdirs) {
        push @all_subdirs, ( $filter->($d) ? $d : () ), $d->subdirs_rec();
    }
    return @all_subdirs;
}
### INSTANCE METHOD
# Subroutine: dirs
# Usage: $dir->dirs( $filter )
# Purpose: 
# Returns: 
#   A list of all contained directories s.t. $filter->($dir) is true.
#   A list of all contained directories otherwise.
# Throws: Nothing
sub dirs {
    my $self = shift;
    my ($filter) = @_;
    $filter = $filter || sub { 1 };
    my @all_dirs;
    push @all_dirs, $self if $filter->( $self );
    push @all_dirs, $self->subdirs_rec( $filter );
    return @all_dirs;
}

### INSTANCE METHOD
# Subroutine: image_dirs
# Usage: $dir->image_dirs(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub image_dirs {
    my $self = shift;
    return $self->dirs(sub {scalar (@{$_[0]->images})});
}
### INSTANCE METHOD
# Subroutine: all_images
# Usage: $dir->all_images(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub all_images {
    my $self = shift;
    return ( map { (@{$_->images}) } $self->image_dirs );
}

### INSTANCE METHOD
# Subroutine: non_discs
# Usage: $dir->non_discs(  )
# Purpose: Find all the non-disc directories at or below $dir.
# Returns: A list of What::Release::Directory objects.
# Throws: Nothing
sub non_discs {
    my $self = shift;
    my @discs;
    push @discs, $self if $self->is_disc;
    push @discs, $self->contained_non_discs();
    return @discs;
}
### INSTANCE METHOD
# Subroutine: discs
# Usage: $dir->discs(  )
# Purpose: Find all the disc directories at or below $dir.
# Returns: A list of What::Release::Directory objects.
# Throws: Nothing
sub discs {
    my $self = shift;
    my @discs;
    push @discs, $self if $self->is_disc;
    push @discs, $self->contained_discs();
    return @discs;
}

### INSTANCE METHOD
# Subroutine: contained_discs
# Usage: $dir->contained_discs(  )
# Purpose: Find all the disc directories contained strictly below in $dir.
# Returns: A list of What::Release::Directory objects.
# Throws: Nothing
sub contained_discs {
    my $self = shift;
    return $self->subdirs_rec(sub {$_[0]->is_disc});
}
### INSTANCE METHOD
# Subroutine: contained_non_discs
# Usage: $dir->contained_non_discs(  )
# Purpose: Find all the non-disc directories contained strictly below in $dir.
# Returns: A list of What::Release::Directory objects.
# Throws: Nothing
sub contained_non_discs {
    my $self = shift;
    return $self->subdirs_rec(sub {!$_[0]->is_disc});
}

### INSTANCE METHOD
# Subroutine: contains_discs
# Usage: $dir->contains_discs(  )
# Purpose: Determine if there are any discs descendant of $dir.
# Returns: A boolean value.
# Throws: Nothing
sub contains_discs {
    my $self = shift;
    return scalar ($self->discs()) > 0;
}

### INSTANCE METHOD
# Subroutine: audio_files
# Usage: $release_directory->audio_files(  )
# Purpose: Create a list of all audio files in the release.
# Returns: A list of audio file paths.
# Throws: Nothing
sub audio_files {
    my $self = shift;
    return (map {@{$_->songs}} $self->discs());
}

### INSTANCE METHOD
# Subroutine: files
# Usage: $release_directory->files(  )
# Purpose: Create a list of all the files in the release.
# Returns: A list of file paths.
# Throws: Nothing
sub files {
    my $self = shift;
    return (
        ($self->nfo ? ($self->nfo) : ()),
        @{$self->songs},
        @{$self->m3us},
        @{$self->logs},
        @{$self->cues},
        @{$self->images},
        @{$self->other_files},
        (map {$_->files()} @{$self->subdirs}));
}

### INSTANCE METHOD
# Subroutine: file_format
# Usage: $dir->file_format(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub file_format {
    my $self = shift;
    my $format;
    if ($self->is_disc) {
        for my $song (@{$self->songs}) {
            my $song_format = $song =~ m/\. (\w+) \z/xms ? file_format_of($1) : undef;

            UnknownError->throw(error => "No extension on '$song'") 
                if !defined $song_format;

            if (!defined $format) {
                $format = $song_format;
            }
            elsif ( !($song_format eq $format) ) {
                MultipleFormatsError->throw(
                    error => "Found audio formats $song_format and $format");
            }
        }
        return $format;
    }
    else {
        my @discs = $self->discs();
        my @disc_formats = map {$_->file_format()} @discs;
        for my $f (@disc_formats) {
            if (!defined $format) {
                $format = $f;
            }
            elsif ( !($f eq $format) ) {
                MultipleFormatsError->throw(
                    error => "Found audio formats $format and $format");
            }
        }
        return $format;
    }
}

### INSTANCE METHOD
# Subroutine: has_m3u
# Usage: $disc_directory->has_m3u(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub has_m3u {
    my $self = shift;
    return @{$self->m3us} > 0;
}

### INSTANCE METHOD
# Subroutine: has_cue
# Usage: $disc_directory->has_cue(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub has_cue {
    my $self = shift;
    return @{$self->cues} > 0;
}

### INSTANCE METHOD
# Subroutine: has_log
# Usage: $disc_directory->has_log(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub has_log {
    my $self = shift;
    return @{$self->logs} > 0;
}

### INSTANCE METHOD
# Subroutine: make_subdir
# Usage: 
#   $dir->make_subdir( 
#       name    => $directory_name;
#       verbose => $verbose, 
#       dry_run => $dry_run
#   )
# Purpose: Find/create a subdirectory.
# Returns: A What::Release::Directory instance.
# Throws: Nothing
sub make_subdir {
    my $self = shift;
    my ( %arg ) = @_;
    my $dir_name = $arg{name};
    if ($dir_name =~ m!/!xms) {
        Error->throw(error => "Invalid directory name '$dir_name'");
    }
    my $dir_path = sprintf '%s/%s', $self->path, $dir_name;
    for my $d (@{$self->subdirs}) { return $d if $d->path eq $dir_path; }
    subsystem(
        cmd => ['mkdir', $dir_path],
        verbose => $arg{verbose}, 
        dry_run => $arg{dry_run},
    ) == 0
        or Error->throw(error => "Couldn't make directory '$dir_path'.");
    my $dir = What::Release::Directory->new(
        path => $dir_path,
        name => $dir_name,);
    push @{$self->subdirs}, $dir;
    return $dir;
}

sub _parse_directory {
    my ( $dir, $name ) = @_;

    # Check that the directory exists and is readable.
    FileDoesNotExistError->throw(error => "Directory $dir does not exist.")
        if !-e $dir;
    FilePermissionsError->throw(error => "$dir is not a directory.")
        if !-d $dir;
    FilePermissionsError->throw(error => "Directory $dir is not readable.")
        if !-r $dir;

    # Fill out the attributes.
    my %rdir = ( 
        path => $dir,
        ($name ? (name => $name) : ()),
        songs => [],
        m3us => [],
        cues => [],
        logs => [],
        images => [],
        other_files => [],
        subdirs => [],
    );
    my $path_len = length $dir;
    
    # Detect format and find the disc directories.
    my @hidden_files = find_file_pattern('.*', $dir);
    $rdir{hidden_files} = [@hidden_files];

    my @files = find_file_pattern('*', $dir);

    my $audio_ext_p = qr{(?: flac | mp3 | ogg | m4a )}ixms;
    my $is_audio_file = sub {$_[0] =~ m/\A ($audio_ext_p) \z/ixms};
    my $img_ext_p = qr{(?: jpg | jpeg | png | tiff )}ixms;
    my $is_image = sub {$_[0] =~ m/\A ($img_ext_p) \z/ixms};
    my $is_bbinfo = sub {$_[0] =~ m/ Info\.txt \z/xms};

    for my $file (@files) {
        my $file_ext = $file =~ m/\. (\w+) \z/xms ? lc $1 : undef;
        if (-d $file) {
            my $d_name = ($name ? "$name - " : q{}) . basename($file);
            my %d = _parse_directory($file, $d_name);
            my $subdir = What::Release::Directory->new( %d );
            $subdir->is_disc(1) if @{$subdir->songs};
            push @{$rdir{subdirs}}, $subdir;
        }
        elsif (!defined $file_ext) { push @{$rdir{other_files}}, $file; }
        elsif ($is_bbinfo->($file)) { push @{$rdir{other_files}}, $file; }
        elsif ($file_ext eq 'log') { push @{$rdir{logs}}, $file; }
        elsif ($file_ext eq 'cue') { push @{$rdir{cues}}, $file; }
        elsif ($file_ext eq 'nfo') { $rdir{nfo} = $file; }
        elsif ($file_ext eq 'm3u') { push @{$rdir{m3us}}, $file; }
        elsif ($is_image->($file_ext)) { push @{$rdir{images}}, $file }
        elsif ($is_audio_file->($file_ext)) { 
            push @{$rdir{songs}}, $file; $rdir{is_disc} = 1; }
        else { push @{$rdir{other_files}}, $file; }
    }

    return %rdir;
}

sub _verify_non_disc_dir {
    my $d = shift;
    return if $d->is_disc;
    UnexpectedFile->throw(error => "Log file in non-disc dir.") 
        if ($d->has_log());
    UnexpectedFile->throw(error => "Cue file in non-disc dir.") 
        if ($d->has_cue());
    return;
};

sub _verify_dirs {
    my $d = shift;
    _verify_non_disc_dir($d);
    for my $subd (@{$d->subdirs}) {
        _verify_dirs($subd);
    }
}

### INTERFACE SUB
# Subroutine: scan_release_dir
# Usage: scan_release_dir( $dir )
# Purpose: Create a new What::Release::Directory object from the contents of $dir.
# Returns: Nothing
# Throws: Nothing
sub scan_release_dir {
    my ( $dir ) = @_;
    my %rdir_attr = _parse_directory($dir);
    $rdir_attr{is_root} = 1;

    my $rdir = What::Release::Directory->new(%rdir_attr);

    my $format = $rdir->file_format();
    my @discs = $rdir->discs();
    for my $disc (@discs) {
        my @nested_discs = $disc->contained_discs();
        if (@nested_discs) {
            my @nested_disc_names = map {$_->name} @nested_discs;
            my $nested_disc_str = join q{, }, (map {"'$_'"} @nested_disc_names);
            my $nest_err = sprintf "Nested discs found in directory '%s'; %s",
                $disc->name, $nested_disc_str;
            NestedDiscError->throw(error => $nest_err);
        }
    }

    _verify_dirs($rdir);

    return $rdir;
}

### INTERFACE SUB
# Subroutine: scan_rip_dir
# Usage: scan_rip_dir(  )
# Purpose: Scan the release contained in the rip directory.
# Returns: A new What::Release::Directory object.
# Throws: Nothing
sub scan_rip_dir { return scan_release_dir(whatrc->rip_dir); }

return 1;
__END__

=head1 NAME

What::Release::Directory - Release directory object.

=head1 VERSION

Version 00.00_01

=head1 DESCRIPTION

Release directory object.

=head1 AUTHOR

Bryan Matsuo [bryan.matsuo@gmail.com]

=head1 BUGS

=over

=back

=head1 COPYRIGHT & LICENCE

(c) Bryan Matsuo [bryan.matsuo@gmail.com]
