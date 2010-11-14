#!/usr/bin/env perl
# Use perldoc or option --man to read documentation
package What::Format::FLAC;

our $VERSION = "0.0_1";

use strict;
use warnings;
use Carp;

use Audio::FLAC::Header;
use Moose;

has 'head' => (isa => 'Audio::FLAC::Header', is => 'rw', required => 1);
has 'tag_map' => (isa => 'HashRef[Str]', is => 'rw', required => 1);
has 'tags_are_modified' => (isa => 'Bool', is => 'rw', default => 0);

require Exporter;
use AutoLoader qw(AUTOLOAD);
our @ISA; 
push @ISA, 'Exporter';

# If you do not need this, 
#   moving things directly into @EXPORT or @EXPORT_OK will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw{
    read_flac
};


### INSTANCE METHOD
# Subroutine: _tag_name_
# Usage: $self->_tag_name_( $tag )
# Purpose: Get the name for $tag used by this particular FLAC file.
# Returns: Nothing
# Throws: Nothing
sub _tag_name_ {
    my $self = shift;
    my ($tag) = @_;
    return if !defined $tag;
    return $self->tag_map->{uc $tag} || uc $tag;
}

### INSTANCE METHOD
# Subroutine: tag_value
# Usage: 
#   $flac->tag( $tag )
#   $flac->tag( $tag, $new_value )
# Purpose: 
#   Return the value of a tag.
#   If, a second argument is given the tag is set, and the new value returned.
#   The case of $tag is irrelevant because all tags are normalized.
# Returns: A string if the tag is present. Undef otherwise.
# Throws: Nothing
sub tag {
    my $self = shift;
    my ($tag, $new_val) = @_;
    
    my $tag_name = $self->_tag_name_($tag);
    if (!defined $new_val) {
        my $tag_val = $self->head->{info}->{tags}->{$tag_name};
        return $tag_val;
    }
    $self->head->{info}->{tags}->{$tag_name} = $new_val;
    $self->tag_map->{uc $tag_name} = $tag_name;
    $self->tags_are_modified = 1;
    return $new_val;
}

### INSTANCE METHOD
# Subroutine: write_tags
# Usage: $self->write_tags(  )
# Purpose: Attempt to write out any modified tag values for flac.
# Returns: 0 <=> The tags failed to be written.
# Throws: Nothing
sub write_tags {
    my $self = shift;
    return 1 if !$self->tags_are_modified;
    my $res = $self->head->write();
    $self->tags_are_modified = 0 if $res != 0;
    return $res;
}

### INTERFACE SUB
# Subroutine: read_flac
# Usage: read_flac( $flac_path )
# Purpose: Read the contents of a given FLAC file.
# Returns: A new What::Format::FLAC object.
# Throws: Nothing
sub read_flac {
    my ($flac_path) = @_;
    
    my $head = Audio::FLAC::Header->new($flac_path);
    my %tag_map = uniform_tag_map($head->{info});

    return What::Format::FLAC->new(
        head => $head, 
        tag_map => \%tag_map);
}

### INTERNAL SUBROUTINE
# Subroutine: uniform_tag_map
# Usage: uniform_tag_map( $flac_info )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub uniform_tag_map {
    my ($flac_info) = @_;

    my %tag_name;
    my $tag_ref = $flac_info->{tags};

    for my $tag (keys %{ $tag_ref }) {
        $tag_name{uc $tag} = $tag;
    }

    return %tag_name;
}

return 1;

__END__

=head1 NAME

FLAC - Interface for dealing with flac files and their tags.

=head1 VERSION

Version 0.0_1

Originally created on 11/14/10 01:04:50

=head1 DESCRIPTION

This library is meant to deal with the nitty gritty parts of FLAC files,
such as non-uniform tag capitalization.

=head1 AUTHOR

Bryan Matsuo [bryan.matsuo@gmail.com]

=head1 BUGS

=over

=back

=head1 COPYRIGHT & LICENCE

(c) Bryan Matsuo [bryan.matsuo@gmail.com]
