package What::Discogs::Discography;
use strict;
use warnings;
use Carp;
use What::XMLLib;

use What::Discogs::Base;
use Moose;
extends 'What::Discogs::Base';

has 'name' => ('isa' => 'Str', 'is' => 'rw', 'required' => 1);
has 'urls' => ('isa' => 'ArrayRef[Str]', 'is' => 'rw', 'required' => 0,
    default => sub { [] });
    
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
