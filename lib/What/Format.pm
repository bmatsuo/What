#!/usr/bin/env perl

# Use perldoc or option --man to read documentation
package What::Format;

# include some core modules
use strict;
use warnings;
use Carp;
use File::Basename;

use Exception::Class ('ExtensionException');

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
    formats
    format_normalized
    format_is_accepted
    format_extension
    transcode_path
);

our $VERSION = '0.0_3';

my %is_accepted = (
    FLAC    => 1,
    OGG     => 1,
    AAC     => 1,
    320     => 1,
    V0      => 1,
    V2      => 1,
);

my %ext_of = (
    FLAC    => 'flac',
    OGG     => 'ogg',
    AAC     => 'm4a',
    320     => 'mp3',
    V0      => 'mp3',
    V2      => 'mp3',
);

# Subroutine: formats()
# Type: INTERFACE SUB
# Returns: List of the valid formats.
sub formats {
    return keys %is_accepted;
}


# INTERFACE METHOD (no class arg);
sub format_normalized {
    my $format = shift;
    uc $format;
}

# INTERFACE METHOD (no class arg);
sub format_is_accepted{
    my $format = format_normalized(shift @_);
    return if !$is_accepted{$format};
    return $format;
}

# INTERFACE METHOD (no class arg);
sub format_extension {
    my $format = shift;
    return $ext_of{format_normalized($format)};
}

# Subroutine: transcode_path($file, $dest, $format)
# Type: INTERFACE SUB
# Purpose: 
#   Create the filename for a transcode of $file to $format,
#   placed in the directory $dest.
# Returns: The path to the converted file.
sub transcode_path {
    my ($file, $dest, $format) = @_;
    my $new_ext = format_extension($format);
    my $name = basename($file);
    if ($name =~ s/(.)\.\w+ \z/$1.$new_ext/xms) {
        return "$dest/$name";
    }
    else {
        ExtensionException->throw(error => "File $file has no extension.\n");
    }
}

1;
__END__

=head1 NAME

What::Format
-- A module for dealing with formats in the What package.

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
