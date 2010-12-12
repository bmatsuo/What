#!/usr/bin/env perl
# Use perldoc or option --man to read documentation
# Originally created on 12/11/10 23:37:18
package What::Release::DiscDirectory;
use strict;
use warnings;
use Moose;
has 'path' => (isa => 'Str', is => 'rw', required => 1);
has 'name' => (isa => 'Str', is => 'rw', required => 1);
has 'logs' => (isa => 'ArrayRef[Str]', is => 'rw');
has 'cues' => (isa => 'ArrayRef[Str]', is => 'rw');
has 'm3us' => (isa => 'ArrayRef[Str]', is => 'rw');
has 'songs' => (isa => 'ArrayRef[Str]', is => 'rw');
has 'other_files' => (isa => 'ArrayRef[Str]', is => 'rw');

package What::Release::Directory;
use strict;
use warnings;
use File::Basename;
use What::Format;
use What::Utils qw{:files :dirs};
use What::Exceptions::Common;

use Exception::Class (
    'NoAudioError', 
    'MultipleFormatsError', 'UnknownFormatError',
    'UnexpectedFile',);

use Moose;
has 'path' => (isa => 'Str', is => 'rw', required => 1);
has 'file_format' => (isa => 'Str', is => 'rw', required => 1);
has 'nfo' => (isa => 'Str', is => 'rw');
has 'm3us' => (isa => 'ArrayRef[Str]', is => 'rw');
has 'images' => (isa => 'ArrayRef[Str]', is => 'rw');
has 'discs' 
    => ( isa => 'ArrayRef[What::Release::DiscDirectory]',
        is => 'rw');
has 'other_files' => (isa => 'ArrayRef[Str]', is => 'rw');

### INTERFACE SUB
# Subroutine: scan_release_dir
# Usage: scan_release_dir( $dir )
# Purpose: Create a new What::Release::Directory object from the contents of $dir.
# Returns: Nothing
# Throws: Nothing
sub scan_release_dir {
    my ( $dir ) = @_;

    # Check that the directory exists and is readable.
    FileDoesNotExistError->throw(error => "Directory $dir does not exist.")
        if !-e $dir;
    FilePermissionsError->throw(error => "$dir is not a directory.")
        if !-d $dir;
    FilePermissionsError->throw(error => "Directory $dir is not readable.")
        if !-r $dir;

    # Fill out the attributes.
    my %rdir 
        = ( path => $dir,
            other_files => [],
            m3us => [],
            images => [],
            discs => [],);
    my $path_len = length $dir;
    
    # Detect format and find the disc directories.
    my @files = find_hierarchy($dir);
    my @audio_files = grep {m/\. (flac | mp3 | ogg | m4a) \z/ixms}
    if (!@audio_files) {
        NoAudioError->throw(error => "No audio files found.");
    }
    my @audio_types = map {m/\. (\w+) \z/xms} @audio_files;
    my %has_audio_file_format = (map {($_ => 1)} @audio_files);
    @audio_types = keys %has_audio_file_format;
    if (!@audio_types) {
        NoAudioError->throw(error => "Couldn't detect any audio file types.");
    }
    my $audio_ext = $audio_types[0];
    if (@audio_types > 1) {
        MultipleFormatsError->throw(error => "Multiple audio formats found @audio_types.");
    }
    else {
        my $format = file_format_of($audio_types[0]);

        # This should never be thrown.
        UnknownFormatError->throw(error => 'Unknown format; $audio_types[0]') 
            if !defined $format;

        $rdir{file_format} = $format;
    }
    my %has_audio_files = (map {(dirname($_) => 1)} @audio_files);
    my @disc_dir_paths = keys %has_audio_files;
    my $root_is_disc_dir;
    my $file_is_in_a_disc = sub {
        my $file = shift;
        my $d = dirname($file);
        while ( defined $d && !($d eq q{/} || $d eq q{.}) ) {
            return 1 if $has_audio_files{$d};
            my $new_d = dirname($d);
            if ($new_d eq $d) {
                my $err = 'Unforeseen infinite loop in scan_release_dir';
                UnknownError->throw(error => $err);
            }
            $d = $new_d;
        }
        return 0;
    };

    # Scan each disc directory.
    for my $disc_path (@disc_dir_paths) {
        my %disc = (
            path => $disc_path,
            songs => [],
            m3us => [],
            cues => [],
            logs => [],
            other_files => []);

        my $disc_name = substr $disc_path, $path_len + 1, length ($disc_path) - $path_len - 1;
        $disc_name =~ s!/! - !xms;
        $disc{name} = $disc_name;
        $root_is_disc_dir = 1 if $disc_name eq q{};

        my $disc_files = find_hierarchy($disc_path);
        for my $disc_file (@disc_files) {
            my $file_ext = $disc_file =~ m/\. (\w+) \z/xms ? lc $1 : undef;
            if (!defined $file_ext) {
                # Classify non-subdirectories with no extension.
                push @{$disc{other_files}}, $disc_file if !-d $disc_file;
            }
            elsif ($file =~ m/ Info\.txt \z/xms) {
                # Pass on these files.
            }
            elsif ($file_ext =~ m/\A $audio_ext \z/xms) {
                push @{$disc{songs}}, $disc_file;
            }
            elsif ($file_ext eq 'log') {
                push @{$disc{logs}}, $disc_file;
            }
            elsif ($file_ext eq 'cue') {
                push @{$disc{cues}}, $disc_file;
            }
            elsif ($file_ext eq 'm3u') {
                push @{$disc{m3us}}, $disc_file;
            }
            elsif ($file_ext eq 'nfo') {
                if ( !$disc_name eq q{} ) {
                    push @{$disc{other_files}}, $disc_file;
                }
            }
            elsif ($file_ext =~ m/\A (jpg | jpeg | png | tiff) \z/xms) {
                # Do nothing for images.
            }
            else {
                push @{$disc{other_files}}, $disc_file;
            }
        }
        push @{$rdir{discs}}, What::Release::DiscDirectory->new(%disc);
    }

    for my $file (@files) {
        my $in_a_disc = $file_is_in_a_disc->($file);
        my $file_ext = $file =~ m/\. (\w+) \z/xms ? lc $1 : undef;
        if (!defined $file_ext) {
            if (!-d $file && !$in_a_disc) {
                # Classify non-subdirectories with no extension.
                push @{$rdir{other_files}}, $file;
            }
        }
        elsif ($file =~ m/ Info\.txt \z/xms) {
            push @{$rdir{other_files}}, $file;
        }
        elsif ($file_ext =~ m/\A (flac | mp3 | ogg | m4a) \z/xms) {
            UnexpectedFile->throw(error => "Audio file not in disc; $file")
                if !$in_a_disc;
        }
        elsif ($file_ext eq 'log') {
            UnexpectedFile->throw(error => "Log not in disc; $file")
                if !$in_a_disc;
        }
        elsif ($file_ext eq 'cue') {
            UnexpectedFile->throw(error => "Cue not in disc; $file")
                if !$in_a_disc;
        }
        elsif ($file_ext eq 'nfo') {
            $rdir{nfo} = $file;
        }
        elsif ($file_ext eq 'm3u') {
            push @{$rdir{m3us}}, $file if !$in_a_disc;
        }
        elsif ($file_ext =~ m/\A (jpg | jpeg | png | tiff) \z/xms) {
            push @{$rdir{images}}, $file
        }
        else {
            push @{$rder{other_files}}, $file if !$in_a_disc;
        }
    }

    return What::Release::Directory->new(%rdir);
}

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
