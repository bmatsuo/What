package What::Release;

use 5.008009;
use strict;
use warnings;
use Carp;

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
    artist  => "",
    title   => "",
    year    => "",
    label   => "",
    desc    => "",);

# Subroutine: 
#   What::Release->new(
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

    my $name = "$self->{artist} - $self->{year} - $self->{title}";
    return $name;
}

# Subroutine: $release->dir($rip_dir)
# Type: INSTANCE METHOD
# Purpose: 
#   Compute the release's root directory, given the rip root directory.
# Returns: A path to the release's root directory.
sub dir {
    my $self = shift;

    my $rip_root = shift;

    my $name = $self->name();

    my $release_root = "$rip_root/$self->{artist}/$name";

    return $release_root;
}

# Subroutine: $release->format_dir($rip_dir, $format)
# Type: INSTANCE METHOD
# Purpose: 
#   Compute the release's root directory, given the rip root directory.
# Returns: A path to the release's root directory.
sub format_dir {
    my $self = shift;

    my $rip_root = shift;

    my $format = shift;

    my $release_name = $self->name();
    my $release_root = $self->dir($rip_root);

    my $format_dir = "$release_root/$release_name [$format]";

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

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut