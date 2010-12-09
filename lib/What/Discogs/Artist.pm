use strict;
use warnings;
use Carp;
use What::XMLLib;

package What::Discogs::Artist::Name;
use Moose;

has 'name'
    => (isa => 'Str', is => 'rw', required => 1,);
has 'copy'
    => (isa => 'Int', is => 'rw', required => 0);

# Subroutine: $name->discogs_name()
# Type: INSTANCE METHOD
# Purpose: Combine the name and copy number for using in a Discogs query.
# Returns: "$name ($copy_number)"
sub discogs_name {
    my $self = shift;
    my $cp_num = $self->copy();
    my $is_dup = defined $cp_num && $cp_num > 0;
    my $copy_suffix = $is_dup ? qq{ ($cp_num)} : q{};
    return $self->name() . $copy_suffix;
}

package What::Discogs::Artist::Release;
use What::Discogs::Release;
use Moose;
extends 'What::Discogs::Release::Reference::Base';

has 'year' => (isa => 'Str', 'is' => 'rw', 'required' => 0);
has 'type' => ('isa' => 'Str', 'is' => 'rw', 'required' => 1);
has 'label' => ('isa' => 'Str', 'is' => 'rw', 'required' => 1);
# Maybe should be required for featured artist releases...
has 'track_info' => ('isa' => 'Str', 'is' => 'rw', 'required' => 0);

package What::Discogs::Artist;
use Moose;

# Copy number of the artist name (e.g. 'M.I.A (2)' has copy number of 2).
has 'name' 
    => (isa => 'What::Discogs::Artist::Name',
        is => 'rw',
        required => 1);
has 'name_variations' 
    => (isa => 'ArrayRef[Str]', 
        is => 'rw', 
        default => sub { [] });
has 'urls' 
    => (isa => 'ArrayRef[Str]', 
        is => 'rw', 
        default => sub { [] });
has 'aliases' 
    => (isa => 'ArrayRef[Str]', 
        'is' => 'rw', 
        default => sub { [] });
has 'members' 
    => (isa => 'ArrayRef[Str]', 
        is => 'rw',
        default => sub { [] });
has 'releases' 
    => (isa => 'ArrayRef[What::Discogs::Artist::Release]', 
        is => 'rw', 
        default => sub { [] });

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What::Discogs::Artist
-- A class for an artist discography.

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

=item What::Discogs::Release

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
