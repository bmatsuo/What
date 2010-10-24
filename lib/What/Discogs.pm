package What::Discogs;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use What::Discogs::Artist;
use What::Discogs::Label;
use What::Discogs::Query;
use What::Discogs::Release;
use What::Discogs::Search;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use what ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    get_release
    get_artist
    get_label
    search
);

our $VERSION = '0.00_01';

my $agent = LWP::UserAgent->new(agent => 'Mozilla/5.0');

# Subroutine: get_artist(
#   name => $artist_name,
#   api => $api_key,
# )
# Type: INTERFACE SUB
# Purpose: Fetch and parse a Discogs artist page.
# Returns: 
#   A What::Discogs::Artist object for the artist if the page is found.
#   Returns undef if the page is not found.
sub get_artist {
    my %arg = @_;
    my $name = $arg{name};
    my $api = $arg{api};

    my $q = What::Discogs::Query::Artist->new(
        name => $name,
        api => $api,);

    return $q->artist();
}

# Subroutine: get_release(
#   id => $release_id,
#   api => $api_key,
# )
# Type: INTERFACE SUB
# Purpose: Fetch and parse a Discogs release page.
# Returns: 
#   A What::Discogs::Release object for the release if the page is found.
#   Returns undef if the page is not found.
sub get_release {
    my %arg = @_;
    my $id = $arg{id};
    my $api = $arg{api};

    my $q = What::Discogs::Query::Release->new(
        id => $id,
        api => $api,);

    return $q->release();
}

# Subroutine: get_label(
#   name => $label_name,
#   api => $api_key,
# )
# Type: INTERFACE SUB
# Purpose: Fetch and parse a Discogs label page.
# Returns: 
#   A What::Discogs::Label object for the label if the page is found.
#   Returns undef if the page is not found.
sub get_label {
    my %arg = @_;
    my $name = $arg{name};
    my $api = $arg{api};

    my $q = What::Discogs::Query::Label->new(
        name => $name,
        api => $api,);

    return $q->label();
}

# Subroutine: search(
#   qstr => $query_string,
#   api => $api_key,
# )
# Type: INTERFACE SUB
# Purpose: Fetch and parse a Discogs search results page.
# Returns: 
#   A What::Discogs::Search object for the results if the page is found.
#   Returns undef if the page is not found.
sub search {
    my %arg = @_;
    my $qstr = $arg{qstr};
    my $api = $arg{api};

    my $q = What::Discogs::Query::Search->new(
        qstr => $qstr,
        api => $api,);

    return $q->results();
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What::Discogs
-- An interface for the discogs.com webservice.

=head1 SYNOPSIS

    use What::Discogs;
    
    my $api = "XXXXXX" # Use a real discogs.com api key

    # Find all releases for artist Justin Bieber.
    my $search_result_list 
        = What::Discogs::search(
            query => 'Justin Bieber',
            type => 'releases',
            max_pages => '-1',
            api => $api);

    # Find sublist of releases with title 'My World'.
    my $filtered_search 
        = $search_result_list->filter(
            sub {my $r = $_[0]; $r->title eq 'My World'});

    # Find release information.
    my $release = What::Discogs::get_release(
        id => 59180, api => $api);

    my $title = $release->title;
    # $title eq 'A Better Tomorrow EP'

    $search_result_list->DEMOLISH;
    $filtered_search->DEMOLISH;
    $release->DEMOLISH;

=head1 ABSTRACT

The What::Discogs module provieds an object oriented interface with
discogs.com. This allows for programs to search the online release
database for various pieces of information. The produced objects will 
need to be demolished though; as they are stored as inside out classed
using Moose.

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over

=item What::Discogs::Label

=item What::Discogs::Release

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
