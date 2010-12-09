package What::Discogs::Base;
use strict;
use warnings;
use Carp;
use What::XMLLib;

# Private Modules
use Moose;

has 'query' => ('isa' => 'What::Discogs::Query::Base', 'is' => 'rw', 'required' => 1);
has 'images' => ('isa' => 'ArrayRef[Str]', 'is' => 'rw', 'required' => 0,
    default => sub { [] });

### INSTANCE METHOD
# Subroutine: has_images
# Usage: $discogs_obj->has_images(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub has_images {
    my $self = shift;
    return 1 if scalar (@{$self->images} > 0);
    return;
}

### INSTANCE METHOD
# Subroutine: image
# Usage: discogs_obj->image( $ind )
# Purpose: Get the uri of the $ind-th image, starting at 0.
# Returns: Nothing
# Throws: Nothing
sub image {
    my $self = shift;
    my ( $ind ) = @_;
    return $self->images->[$ind];
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What::Discogs::Discography
-- A base class for discographies

=head1 SYNOPSIS

=head1 ABSTRACT

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over

=item What::Discogs::Artist

=item What::Discogs::Label

=item What::Discogs::Release

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
