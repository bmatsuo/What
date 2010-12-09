use strict;
use warnings;
use Carp;
use What::Discogs::Discography;
use What::Discogs::Release;
use What::XMLLib;

package What::Discogs::Label::Release;
use Moose;
extends 'What::Discogs::Release::Reference::Base';

has 'catno' => ('isa' => 'Str', 'is' => 'rw', 'required' => 0);
has 'artist' => ('isa' => 'Str', 'is' => 'rw', 'required' => 1);

package What::Discogs::Label;
use Moose;
extends 'What::Discogs::Discography';

has 'parent' => (isa => 'Str', is => 'rw', 'required' => 0);
has 'sublabels' => (isa => 'Str', is => 'rw', 'required' => 0);
has 'contact' => (isa => 'Str', is => 'rw', 'required' => 0);
has 'profile' => (isa => 'Str', is => 'rw', 'required' => 0);
has 'releases' 
    => (isa => 'ArrayRef[What::Discogs::Label::Release]', 'is' => 'rw', 'required' => 0,
        default => sub { [] });


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What::Discogs::Label
-- A class for a label discography

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

=item What::Discogs::Release

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
