package What::Release;

use 5.008009;
use strict;
use warnings;
use Carp;

use File::Glob 'bsd_glob';
use What::Utils;

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
);

our $VERSION = '0.0_1';

my %def_arg = ( 
    rip_root => "",
    artist  => "",
    title   => "",
    year    => "",
    discs   => 1,
    label   => "",
    desc    => "",);

# Subroutine: 
#   What::Release->new(
#       rip_root=> $rip_root,
#       artist  => $artist,
#       title   => $title,
#       year    => $year,
#       label   => $label,
#       desc    => $description,);
# Type: CLASS METHOD
# Purpose: Create a What::Release object.
#   The constructor requires arguments 'artist', 'title', and 'year'.
#   'label' and 'desc' are optional arguments.
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

# Subroutine: name()
# Type: INSTANCE METHOD
# Purpose: Compute the name of a release.
# Returns: String containing the name of the release.
sub name {
    my $self = shift;
    my $name = "$self->{artist} - $self->{title} ($self->{year})";
    return $name;
}

# Subroutine: $release->artist_dir($upload_root)
# Type: INSTANCE METHOD
# Purpose: 
#   Compute the release's root directory, given the rip root directory.
# Returns: A path to the release's root directory.
sub artist_dir {
    my $self = shift;

    my $rip_root = shift;

    my $name = $self->name();

    my $artist_dir = "$rip_root/$self->{artist}";

    return $artist_dir;
}

# Subroutine: $release->dir($upload_root)
# Type: INSTANCE METHOD
# Purpose: 
#   Compute the release's root directory, given the rip root directory.
# Returns: A path to the release's root directory.
sub dir {
    my $self = shift;

    my $rip_root = shift;

    my $name = $self->name();

    my $artist_dir = $self->artist_dir($rip_root);

    my $release_root = "$artist_dir/$name";

    return $release_root;
}

# Subroutine: $release->format_dir($upload_root, $format)
# Type: INSTANCE METHOD
# Purpose: 
#   Compute the release's root directory, given the rip root directory.
# Returns: A path to the release's root directory.
sub format_dir {
    my $self = shift;

    my $rip_root = shift;

    my $format = uc shift;

    my $release_name = $self->name();
    my $release_root = $self->dir($rip_root);

    my $format_dir = "$release_root/$release_name [$format]";

    return $format_dir;
}

# Subroutine: $release->format_disc_dirs($upload_root, $format);
# Type: INSTANCE METHOD
# Purpose: Find all disc directories in a rip directory.
# Returns: 
#   A list of disc directories (containing music) for a given format.
sub format_disc_dirs {
    my $self = shift;
    my ($upload_root, $format) = @_;

    my $format_dir = $self->format_dir($upload_root, $format);

    my @disc_dirs = bsd_glob(glob_safe($format_dir)."/CD*/");

    # Remove trailing / from directories.
    map {chop $_} @disc_dirs;

    return @disc_dirs if (@disc_dirs);
    
    return $format_dir;
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
