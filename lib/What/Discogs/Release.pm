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
use Moose;

has 'name' => (isa => 'Str', is => 'rw', 'required' => 1);
has 'copy_number' => (isa => 'Int', is => 'rw', 'required' => 0);
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

has 'artists' => (isa => 'ArrayRef[Str]', is => 'rw', 'required' => 0,
    default => sub { [] });
has 'position' => (isa => 'Str', is => 'rw', required => 0);
has 'title' => (isa => 'Str', is => 'rw', required => 0);
has 'duration' => (isa => 'Str', is => 'rw', required => 0);
has 'extra_artists' 
    => (isa => 'ArrayRef[What::Discogs::Release::Track::ExtraArtist]', is => 'rw',
        default => sub { [] }, required => 0);

package What::Discogs::Release::Format;
use Moose;

has 'type' => (isa => 'Str', is => 'rw', required => 1);
has 'quantity' => (isa => 'Int', is => 'rw', required => 1);
has 'descriptions' => (isa => 'ArrayRef[Str]', is => 'rw', required => 0,
    default => sub { [] },);

package What::Discogs::Release;
use Moose;
extends 'What::Discogs::Base';

has 'title' => (isa => 'Str', is => 'rw', 'required' => 1);
has 'artists' => (isa => 'ArrayRef[Str]', is => 'rw', 'required' => 1);
has 'formats' 
    => (isa => 'ArrayRef[What::Discogs::Release::Format]', is => 'rw', 'required' => 1);
has 'labels' => (isa => 'ArrayRef[What::Discogs::Release::Label]', is => 'rw',
    default => sub { [] });
has 'country' => (isa => 'Str', is => 'rw', 'required' => 1);
has 'genres' => (isa => 'ArrayRef[Str]', is => 'rw', 'required' => 0,
    default => sub { [] });
has 'styles' => (isa => 'ArrayRef[Str]', is => 'rw', 'required' => 0,
    default => sub { [] });
has 'date' => (isa => 'Str', is => 'rw', 'required' => 1);
has 'note' => (isa => 'Str', is => 'rw', 'required' => 0);
has 'tracks' 
    => (isa => 'ArrayRef[What::Discogs::Release::Track]', is => 'rw', 'required' => 0,
        default => sub { [] });

# Subroutine: $release->num_tracks()
# Type: INSTANCE METHOD
# Returns: The number of tracks belonging to $release.
sub num_tracks {
    my $self = shift;
    return scalar @{$self->tracks};
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

Bryan Matsuo, <bryan.matsuo@gmail.com>

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
