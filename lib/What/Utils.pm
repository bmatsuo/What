package What::Utils;

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
my @INTERFACE_SUBS = qw{
    format_args
    get_flac_tag
    get_flac_tags
    glob_safe
    find_file_pattern
    search_hierarchy
    find_hierarchy
    find_subdirs
    merge_structure
    align
    words_fit
};
our %EXPORT_TAGS = ( 
    'all' => [ @INTERFACE_SUBS ], 
    'http' => [ qw( format_args ) ],
    'flac' => [qw(  get_flac_tag    get_flac_tags )], 
    'files' => [ qw(    glob_safe   find_file_pattern   search_hierarchy ) ],
    'dirs' => [ qw( find_subdirs    find_hierarchy      merge_structure) ],
    'align' => [ qw(    align   words_fit ) ], );

our @EXPORT_OK = ( 
    @{ $EXPORT_TAGS{'all'} }, 
    # The rest are redundant as long as :all includes all methods.
    # :all may be removed though... There are a diverse array of methods here.
    #@{ $EXPORT_TAGS{'http'} }, 
    #@{ $EXPORT_TAGS{'flac'} },
    #@{ $EXPORT_TAGS{'files'} },
    #@{ $EXPORT_TAGS{'dirs'} },
    #@{ $EXPORT_TAGS{'align'} }, 
);

# TODO: In all programs, add import only necessary tags to 'use What::Utils'.
our @EXPORT = (@INTERFACE_SUBS);

our $VERSION = '0.00_02';

################
# FLAC METHODS #
################

# Subroutine: get_flac_tags($flac_info, @tags)
# Type: INTERFACE SUB
# Purpose: 
#   Get a list of tag values for a list of tags in a given order.
# Returns: 
#   The value of get_flac_tag($flac_info, $t) for $t in @tags.
#   Tags which are not present in the FLAC are represented by the value undef;
#   Returns and undefined value (empty list) if not given any tags.
sub get_flac_tags {
    my ($flac, @tags) = @_;
    return if !@tags;
    return map {get_flac_tag($flac, $_) || undef} @tags;
}


# Subroutine: get_flac_tag($flac_info, $tag)
# Type: INTERFACE SUB
# Purpose: 
#   Find the value of the $tag tag in $flac_info, 
#   an Audio::FLAC::Header object.
# Returns: 
#   The string value of the tag, or undef if the tag does not exist.
sub get_flac_tag {
    my ($flac, $tag) = @_;
    my %tag_val = %{ $flac->{tags} };

    # Create lower case, upper case, and standardly capitilized tag name.
    my @possible_names = (lc $tag, uc $tag, ucfirst lc $tag);

    # Look for any value defined for one of the possible names.
    my @tag_vals = grep {defined $_} map {$tag_val{$_}} @possible_names;
    my $val = shift @tag_vals;

    return if !defined $val;
    return $val;
}

#####################
# ALIGNMENT METHODS #
#####################

# Subroutine: align($str1, $str2)
# Type: INTERFACE SUB
# Purpose: Perform weak string comparison.
# Returns: 
#   A score from 0 to 1. Higher numbers meaning a better fit.
sub align {
    my ($s1, $s2) = @_;
    return (words_fit($s1,$s2) + words_fit($s2,$s1)) / 2;
}

# Subroutine: words_fit($words, $string)
# Type: INTERFACE SUB
# Returns: The percentage of words in $string.
sub words_fit {
    my ($words, $string) = @_;
    my @words = grep {$_ =~ m/./xms} (split /[^A-Za-z0-9]+/, $words);
    my $num_words = scalar @words;
    return 0 if $num_words == 0;
    my $words_contained = 0;

    for my $w (@words) {
        my $i = index $string, $w;
        if ($i >= 0) {
            $words_contained++;
        }
    }

    return  $words_contained / $num_words;
}

#####################
# DIRECTORY METHODS #
#####################

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

# Subroutine: find_hierarchy($dir [, $find_hidden])
# Type: INTERFACE SUB
# Purpose: 
#   Find all the files in the hierachy of a given directory.
#   If $find_hidden is given and evaluates true, then hidden files
#   will be included.
# Returns: A list of files in $dir that match $pattern.
#   Directories all always ordered before their contents.
sub find_hierarchy {
    my ($dir, $find_hidden) = @_;

    croak("Given non-directory as second argument $dir") if (!-d $dir);
    my @files = bsd_glob(glob_safe($dir)."/*");

    if ($find_hidden) {
        my @hidden_files = bsd_glob(glob_safe($dir)."/.*");
        shift @hidden_files; shift @hidden_files;
        push @files, @hidden_files;
    }

    my @subdirs = grep {-d $_} @files;
    my @nondirs = grep {!-d $_} @files;

    return (@files, (map {find_hierarchy($_, $find_hidden)} @subdirs));
}

#######################
# FILE SEARCH METHODS #
#######################

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

    croak("Directory not given or not defined.") 
        if !defined $dir;
    croak("File pattern not given or not defined.") 
        if !defined $patt;
    croak("Given non-directory as second argument $dir.") 
        if !-d $dir;

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

######################
# HTTP REQUEST UTILS #
######################

sub format_args {
    my %arg_val = @_;

    for (values %arg_val) { $_ =~ s/\s+/+/xms }

    my $arg_string = join "&", map {"$_=$arg_val{$_}"} keys %arg_val;

    return $arg_string;
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
