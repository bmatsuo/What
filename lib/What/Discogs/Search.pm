use strict;
use warnings;
use Carp;
use What::XMLLib;

package What::Discogs::Search::Result;
use Moose;

has 'type' => ('isa' => 'Str', 'is' => 'rw', required => 1);
has 'title' => ('isa' => 'Str', 'is' => 'rw', required => 1);
has 'number' => ('isa' => 'Int', 'is' => 'rw', required => 1);
has 'uri' => ('isa' => 'Str', 'is' => 'rw', required => 1);
has 'summary' => ('isa' => 'Str', 'is' => 'rw');

sub dup {
    my $self = shift;
    return What::Discogs::Search::Result->new(
        number=>$self->number, type=>$self->type, 
        title=>$self->title, uri=>$self->uri, summary=>$self->summary);
}

sub uri_type {
    my $self = shift;
    my @elements = split "/", $self->uri();
    return $elements[-2];
}

sub uri_identifier {
    my $self = shift;
    my @elements = split '/', $self->uri();
    my $id = $elements[-1];
    $id =~ s/[+]/ /gxms;
    return $id;
}

package What::Discogs::Search::ResultList;
use Moose;

has 'query' => (
    'isa' => 'What::Discogs::Query::Base', 
    'is' => 'rw', 'required' => 1);

has 'results' => (
    'isa' => 'ArrayRef[What::Discogs::Search::Result]', 
    'is' => 'rw', required => 1);

has 'num_results' => (isa => 'Int', is => 'rw', required => 1);
has 'start' => ('isa' => 'Int', 'is' => 'rw', required => 1);
has 'end' => ('isa' => 'Int', 'is' => 'rw', required => 1);

# Access a result by its number;
sub get_result_number {
    my ($self, $num) = @_;
    my $index = $num - $self->start;
    return $self->get_result($index);
}

# Access a result by its index in the SearchResultList;
sub get_result {
    my ($self, $index) = @_;
    # Return undex if $index is not in interval [0, start - end]
    return if $index < 0 or $index > $self->end - $self->start;
    return $self->results->[$index];
}

sub length {
    my $self = shift;
    my $length = $self->end - $self->start;
    return $length;
}

sub dup {
    my $self = shift;
    my @duped_results = map {$_->dup} @{$self->results};
    return What::Discogs::Search::ResultList->new(
        query=>$self->query, start=>$self->start, end=>$self->end, 
        num_results=>$self->num_results,
        results=>\@duped_results,
    );
}

# Instance method.
# Takes a subroutine as an argument and returns a new SearchResultList.
# The argument should accept one argument (a SearchResult) and return 
# a boolean result.
# The contents of the new SearchResultList will contain 
# results for which the argument subruotine returns true.
sub grep {
    my ($self, $sub_should_include) = @_;

    my $new_list = $self->dup;

    $new_list->query(What::Discogs::Query::Base::null_query());

    my @matched_results 
        = grep {$sub_should_include->($_)} @{$self->results};
    my $num_matched = scalar @matched_results;
    my @dupped_matches;
    for my $i (0 .. $num_matched - 1) {
        my $dupped_match = $matched_results[$i]->dup();
        push @dupped_matches, $dupped_match;
        $dupped_match->number($i + 1);
    }

    $new_list->start(1);
    $new_list->end($#dupped_matches + 1);
    $new_list->num_results($#dupped_matches + 1);
    $new_list->results(\@dupped_matches);

    return $new_list;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What::Discogs::Search
-- For managing search results.

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

=item What::Discogs::Artist

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
