package What::Utils;

use 5.008009;
use strict;
use warnings;
use Carp;
use File::Glob 'bsd_glob';
use File::Basename;
use What::Subsystem;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use what ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    glob_safe
    find_file_pattern
    find_hierarchy
    search_hierarchy
    find_subdirs
    merge_structure
);

our $VERSION = '0.00_01';

# Subroutine: merge_structure($skeleton, $body)
# Type: INTERFACE SUB
# Purpose: 
#   Make sure the $body directory has the $skeleton's directory structure.
# Returns: Nothing.
sub merge_structure {
    my ($skeleton, $body) = @_;

    # Check the existence of both directories.
    croak("$skeleton is not a directory.") if !-d $skeleton;
    croak("$body is not a directory.") if !-d $body;

    # Iterate over subdirs
    my @bones = find_subdirs($skeleton);
    for my $bone (@bones) {
        # Look for the subdir in the body.
        my $bone_location = join '/', $body, basename($bone);
        my $body_has_bone = -d $bone_location;

        # Add the subdirectory to the body when we can't find it.
        if (!$body_has_bone) {
            my @add_bone = ('mkdir', $bone_location);
            subsystem(
                cmd => \@add_bone,
                # TODO: turn these args into args of this method.
                dry_run => 0,
                verbose => 0,
            );
        }

        # Merge the subdirectory structure.
        merge_structure($bone, $bone_location);
    }

    return;
}

# Subroutine: find_subdirs($dir)
# Type: INTERFACE SUB
# Returns: List of subdirectories of $dir>
sub find_subdirs {
    my $dir = shift;
    my @subdirs = bsd_glob(glob_safe($dir)."/*/");
    map {$_ =~ s! /\z !!xms} @subdirs;
    return @subdirs;
}

# Subroutine: find_hierarchy($dir)
# Type: INTERFACE SUB
# Purpose: Find all the files in the hierachy of a given directory
# Returns: A list of files in $dir that match $pattern.
#   Directories all always ordered before their contents.
sub find_hierarchy {
    my ($dir) = @_;

    croak("Given non-directory as second argument $dir") if (!-d $dir);
    my @files = bsd_glob(glob_safe($dir)."/*");
    my @subdirs = grep {-d $_} @files;
    my @nondirs = grep {!-d $_} @files;

    return (@files, (map {find_hierarchy($_)} @subdirs));
}

# Subroutine: search_hierarchy($pattern, $dir)
# Type: INTERFACE SUB
# Purpose: Search the hierarchy of $dir for files matching $pattern.
#   $pattern should be be standard string or perl regex.
# Returns: List of files matching $pattern.
sub search_hierarchy {
    my ($pattern, $dir) = @_;
    my @files = find_hierarchy($dir);
    my @matches = grep {basename($_) =~ $pattern} @files;
    return @matches;
}

# Subroutine: find_file_pattern($pattern, $dir)
# Type: INTERFACE SUB
# Purpose: Find files of a given pattern in a directory.
#   The pattern is a standard bsd_glob pattern.
# Returns: A list of files in $dir that match $pattern.
# Example: find_file_pattern('*.mp3', '~/Music/Favorite Band/Album')
sub find_file_pattern {
    my ($patt, $dir) = @_;

    croak("Given non-directory as second argument $dir") if (!-d $dir);

    return bsd_glob(glob_safe($dir)."/$patt");
}

# Subroutine: glob_safe($str)
# Type: INTERFACE SUB
# Purpose: Escape characters in string $str that are special to bsd_glob.
#   The only unescaped character is '~', which should be expanded to a
#   full directory.
# Returns: A copy of $str which can safely be plugged into bsd_glob.
sub glob_safe {
    my $str = shift;

    $str =~ s/(\[|\]|\\|[{}*?])/\\$1/gxms;

    return $str;
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What - A library and program suite to accompany What.CD

=head1 SYNOPSIS

  use What;

=head1 ABSTRACT

The the What package provides several tools to facilitate uploading and
other contributions to the what.cd website.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

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
