use strict;
use warnings;
use Carp;
use What::XMLLib;

package What::Discogs::Release::Reference::Base;
# A base class for objects referring to a Whad::Discogs::Release
use Moose;

has 'title' => (isa => 'Str', 'is' => 'rw', 'required' => 1);
has 'id' => (isa => 'Int', 'is' => 'rw', 'required' => 1);
has 'format' => (isa => 'Str', 'is' => 'rw', 'required' => 1);

package What::Discogs::Release::Label;
use Moose;

has 'name' => (isa => 'Str', is => 'rw', 'required' => 1);
has 'catno' => (isa => 'Str', is => 'rw', 'required' => 0);

package What::Discogs::Release::ExtraArtist::Base;
use What::Discogs::Artist;
use Moose;

has 'name' 
    => (isa => 'What::Discogs::Artist::Name', 
        is => 'rw', 
        required => 1);
has 'role' => (isa => 'Str', is => 'rw', 'required' => 0);

package What::Discogs::Release::ExtraArtist;
use Moose;
extends 'What::Discogs::Release::ExtraArtist::Base';

has 'tracks' => (isa => 'Str', is => 'rw', 'required' => 0);

package What::Discogs::Release::Track::ExtraArtist;
use Moose;
extends 'What::Discogs::Release::ExtraArtist::Base';

package What::Discogs::Release::Track;
use Moose;

has 'artists' 
    => (isa => 'ArrayRef[What::Discogs::Artist::Name]', 
        is => 'rw', 
        required => 0,
        default => sub { [] });
has 'position' => (isa => 'Str', is => 'rw', required => 0);
has 'title' => (isa => 'Str', is => 'rw', required => 0);
has 'duration' => (isa => 'Str', is => 'rw', required => 0);
has 'extra_artists' 
    => (isa => 'ArrayRef[What::Discogs::Release::Track::ExtraArtist]', is => 'rw',
        default => sub { [] }, required => 0);

# Subroutine: $track->disc_pos()
# Type: INSTANCE METHOD
# Purpose: Remove the disc number from the track position (if disc number exists).
# Returns: The position of the track on it's disc.
#   Does nothing for vinyl releases.
sub pos_on_disc {
    my $self = shift;
    my $pos = $self->position();
    $pos =~ s/.*[-.]\s*([A-Z]*\d+)\z/$1/xms;
    return $pos;
}

package What::Discogs::Release::Format;
use Moose;

has 'name' => (isa => 'Str', is => 'rw', required => 0);
has 'type' => (isa => 'Str', is => 'rw', required => 1);
has 'quantity' => (isa => 'Int', is => 'rw', required => 1);
has 'descriptions' => (isa => 'ArrayRef[Str]', is => 'rw', required => 0,
    default => sub { [] },);

package What::Discogs::Release::Disc;
use Moose;

has 'title'
    => (isa => 'Str',
        is => 'rw',
        required => 0,);
has 'number'
    => (isa => 'Int',
        is => 'rw',
        default => 1,);
has 'tracks'
    => (isa => 'ArrayRef[What::Discogs::Release::Track]', 
        is => 'rw',
        default => sub { [] });
has 'media'
    => (isa => 'Str', is => 'rw', default => "CD");

# Subroutine: $disc->num_tracks()
# Type: INSTANCE METHOD
# Purpose: Easily find the number of tracks on the disc.
# Returns: The size of the tracks array.
sub num_tracks {
    my $self = shift;
    return scalar @{$self->tracks()};
}

# Subroutine: $disc->track($track_number)
# Type: INSTANCE METHOD
# Purpose: Retrieve tracks by their number (1 through #tracks)
# Returns: 
#   A What::Discogs::Release::Track object; or undef for an invalid track number.
sub track {
    my $self = shift;
    my $track_num = shift;
    return if $track_num > $self->num_tracks();
    return $self->tracks()->[$track_num - 1];
}

package What::Discogs::Release;
use What::Utils;
use Moose;
extends 'What::Discogs::Base';

has 'title' 
    => (isa => 'Str', 
        is => 'rw', 
        required => 1);
has 'artists' 
    => ( isa => 'ArrayRef[What::Discogs::Artist::Name]', 
        is => 'rw', 
        required => 1);
has 'artist_joins' 
    => (isa => 'ArrayRef[Str]', 
        is => 'rw', 
        default => sub {[]}),;
has 'formats' 
    => (isa => 'ArrayRef[What::Discogs::Release::Format]', 
        is => 'rw', 
        default => sub {[]},);
has 'labels' 
    => (isa => 'ArrayRef[What::Discogs::Release::Label]', 
        is => 'rw',
        default => sub { [] },);
has 'country' 
    => (isa => 'Str', 
        is => 'rw', 
        required => 0);
has 'genres' 
    => (isa => 'ArrayRef[Str]', 
        is => 'rw', 
        default => sub { [] },);
has 'styles' 
    => ( isa => 'ArrayRef[Str]', 
        is => 'rw', 
        default => sub { [] },);
has 'date' => (isa => 'Str', is => 'rw', 'required' => 0);
has 'note' => (isa => 'Str', is => 'rw', default => q{} );
has 'discs' 
    => (isa => 'ArrayRef[What::Discogs::Release::Disc]',
        is => 'rw',
        default => sub { [] },);
# has 'tracks' 
#     => (isa => 'ArrayRef[What::Discogs::Release::Track]', 
#         is => 'rw',
#         default => sub { [] },);

### INSTANCE METHOD
# Subroutine: id
# Usage: $release->id(  )
# Purpose: Retrieve the release's id.
# Returns: Nothing
# Throws: Nothing
sub id {
    my $self = shift;
    return $self->query->id;
}

# Subroutine: $release->artist_string()
# Type: INTERFACE SUB
# Purpose: Create a string from the artist list.
# Returns: Return the list of artists as the string.
sub artist_string {
    my $self = shift;
    my @artists = @{$self->artists()};
    my @joins = @{$self->artist_joins()};
    my $str = '';
    for my $i (0 .. $#artists) {
        my $artist = $artists[$i]->name();
        my $join = $joins[$i];
        $str .= (defined $join and $join =~ /./xms) ? "$artist $join " : $artist;
        if ($i < $#artists && !defined $join) {
            $str .= ', ';
        }
    }
    return $str;
}

### INSTANCE METHOD
# Subroutine: catno_string
# Usage: $self->catno_string(  )
# Purpose: Compact the string of category numbers if possible.
# Returns: Nothing
# Throws: Nothing
sub catno_string {
    my $self = shift;
    my @catnos = map {$_->catno} ($self->labels_in_order);
    my @with_catnos = grep {$_->catno =~ /\S/xms} @{$self->labels};
    my $all_equal = sub { 
        my @strings = @_; my $last; 
        for my $str (@strings) {
            if (!defined $last) { $last = $str; }
            else { return if not $last eq $str; }
        } 1; };
    my $catno_str 
        = !@catnos ? q{}
        : $all_equal->( @catnos ) ? $catnos[0]
        : scalar (@with_catnos) == 1 ? $with_catnos[0]->catno
        : join ", ", @catnos;
    return $catno_str;
}

### INSTANCE METHOD
# Subroutine: label_string
# Usage: $self->label_string(  )
# Purpose: Return the string of labels associated with $release
# Returns: Nothing
# Throws: Nothing
sub label_string {
    my $self = shift;
    return join q{, }, map {$_->name} ($self->labels_in_order);
}

### INSTANCE METHOD
# Subroutine: labels_in_order
# Usage: $self->labels_in_order(  )
# Purpose: Return a properly ordered (parent ... child) list of labels.
# Returns: Nothing
# Throws: Nothing
sub labels_in_order {
    my $self = shift;
    return reverse @{$self->labels};
}

# Subroutine: $release->num_discs()
# Type: INSTANCE METHOD
# Returns: The number of discs belonging to $release.
sub num_discs {
    my $self = shift;
    return scalar @{$self->discs()};
}

# Subroutine: $release->num_tracks()
# Type: INSTANCE METHOD
# Returns: The total number of tracks belonging to $release.
sub num_tracks {
    my $self = shift;
    my $sum = 0;
    for (map {$_->num_tracks} @{$self->discs}) { $sum += $_; }
    return $sum;
}

# Subroutine: $release->tracks()
# Type: INSTANCE METHOD
# Purpose: Aggregate tracks of all discs into a single array.
sub tracks {
    my $self = shift;
    return (map { @{$_->tracks()} } @{$self->discs()});
}

# Subroutine: $release->disc($disc_number)
# Type: INSTANCE METHOD
# Purpose: Retrieve discs by their number (1 through #discs)
# Returns: 
#   A What::Discogs::Release::Disc object; or undef for an invalid disc number.
sub disc {
    my $self = shift;
    my $disc_num = shift;
    return if $disc_num > $self->num_discs();
    return $self->discs()->[$disc_num - 1];
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What::Discogs::Release
-- A class for a discogs release.

=head1 SYNOPSIS

    use What::Discogs::Label;
    
    my $api = "XXXXXX" # Use a real discogs.com api key

    ...

=head1 ABSTRACT

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over

=item What::Discogs

=item What::Discogs::Label

=item What::Discogs::Artist

=item What::Discogs::Search

=item What::Discogs::Query

=back

=head1 AUTHOR

dieselpowered

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by The What team.

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
