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
    format_normalized
    format_is_accepted
    format_extension
);

our $VERSION = '0.0_1';

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

# INTERFACE METHOD (no class arg);
sub format_normalized {
    my $format = shift;
    uc $format;
}

# INTERFACE METHOD (no class arg);
sub format_is_accepted{
    my $format = shift;
    return if !$is_accepted{format_normalized($format)};
    return 1;
}

# INTERFACE METHOD (no class arg);
sub format_extension {
    my $format = shift;
    return $ext_of{format_normalized($format)};
}

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
