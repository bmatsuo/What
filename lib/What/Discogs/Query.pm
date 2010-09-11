use strict;
use warnings;
use Carp;

package What::Discogs::QueryBase;

use LWP::UserAgent;
use What::XMLLib;
use XML::Twig;
use Moose;

has 'api' 
    => ( is => 'rw', 
        required => 1,);
has 'base' 
    => ( is => 'rw', 
        default => 'http://www.discogs.com',);

# This will be oveloaded to return a path like '/artist/Lady+Gaga'
sub path { return '' }

# Get http request arguments in the form of a hash.
sub args {
    my $self = shift;
    return ( 
        'api_key' => $self->api,
        'f' => 'xml',);
}

# Get full http request uri, with arguments.
sub uri {
    my $self = shift;
    return join "", 
        $self->base, $self->path, '?', MyUtils::format_args($self->args);
}

# Submit query and return the xml response
# ... or die (non-optimal handling of failure).
sub fetch {
    my $self = shift;
    #my $resp = LWP::Simple::get($self->uri)
    #    or die q{Couldn't fetch '}.$self->uri.q{'};
    my $ua = LWP::UserAgent->new();
    $ua->agent('Mozilla/5.0');
    $ua->default_header('Accept-Encoding'=>'gzip');
    my $response = $ua->get($self->uri);
    if ($response->is_success) {
        my $gzipped = $response->decoded_content;
        return $gzipped;
    }
    else {
        die $response->status_line."; ".$self->uri;
    }
}

my $null = QueryBase->new(api=>'NULL');

sub null_query {
    return $null
}

sub is_null {
    my $self = shift;
    my $is_null = $self->api eq 'NULL' ? 1 : 0;
    return 1 if $is_null;
    return;
}

package What::Discogs::Query::Artist;
use Moose;
extends 'What::Discogs::Query::Base';

has 'name' => (is => "rw", required => 1);

# Replace any spaces in the name argument with a '+'.
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $rep_spaces = sub {$_[0] =~ s/\s+/+/xms};

    if ( @_ == 1 && !ref $_[0] ) {
        $rep_spaces->($_[0]->{name});
        return $class->$orig(@_);
    }
    elsif ( @_ % 2 == 0 ) {
        my %arg = @_;
        $rep_spaces->($arg{name});
        return $class->$orig(%arg);
    }
    else {
        return $class->$orig(@_);
    }
};

sub path {
    my $self = shift;
    return '/artist/'.$self->name;
};

# Fetch the query, and parse an artist object from the returned xml.
sub artist {
    my $self = shift;

    my %artist;

    $artist{query} = $self;

    my $artist_xml = $self->fetch();

    my $artist_parser = XML::Twig->new();

    #print {\*STDERR} "Parsing xml\n";

    $artist_parser->parse($artist_xml);

    my $resp_root = $artist_parser->root;

    my $artist_root = $resp_root->first_child('artist');

    croak ("Can't find artist in response; ".$self->url) 
        if !defined($artist_root);

    #print {\*STDERR} "Got artist root\n";

    my $db_name = MyUtils::get_first_text('name', $artist_root);

    if ($db_name =~ s/\s+ [(] ( \d+ ) [)] \z//xms) {
        $artist{copy_number} = $1;
    }

    $artist{name} = $db_name;

    #print {\*STDERR} "Got artist name\n";

    my @images 
        = map {$_->text} MyUtils::get_list('images','image',$artist_root);

    my @aliases 
        = map {$_->text} MyUtils::get_list('aliases','name',$artist_root);

    my @variations 
        = map {$_->text} 
            MyUtils::get_list('namevariations','name',$artist_root);

    my @members 
        = map {$_->text} MyUtils::get_list('members','name',$artist_root);

    my @urls
        = map {$_->text} MyUtils::get_list('urls','url',$artist_root);

    my @release_roots 
        = MyUtils::get_list('releases','release', $artist_root);

    for (@images, @aliases, @variations, 
            @urls, @members,) {
        $_ =~ s/ (?: \s | \n )+ \z //xms;
        $_ =~ s/ \A \s+ //xms;
    }

    my @releases;

    #print {\*STDERR} "Parsing releases\n";

    for my $release_root (@release_roots) {
        my $type = $release_root->{'att'}->{'type'};
        my $id = $release_root->{'att'}->{'id'};
        my $title = MyUtils::get_first_text('title', $release_root);
        my $format = MyUtils::get_first_text('format', $release_root);
        my $year = MyUtils::get_first_text('year', $release_root);
        my $label = MyUtils::get_first_text('label', $release_root);
        my $track_info 
            = MyUtils::get_first_text('trackinfo', $release_root);

        my %artist_release = (
            ($type ? (type => $type) : ()), 
            ($id ? (id => $id) : ()), 
            ($title ? (title => $title) : ()), 
            ($format ? (format => $format) : ()), 
            ($year ? (year => $year) : ()), 
            ($label ? (label => $label) : ()), 
            ($track_info ? (track_info => $track_info) : ()),
        );

        for (values %artist_release) {
            $_ =~ s/ (?: \s | \n )+ \z //xms;
            $_ =~ s/ \A \s+ //xms;
        }

        my $release = ArtistRelease->new(%artist_release);

        push @releases, $release;
    }

    %artist = (
        %artist,
        (   (@images ? (images => \@images) : ()), 
            (@aliases ? (aliases => \@aliases) : ()), 
            (@variations ? (name_variations => \@variations) : ()), 
            (@urls ? (urls => \@urls) : ()), 
            (@members ? (members => \@members) : ()), 
            (@releases ? (releases => \@releases) : ()), ),
    );

    return Artist->new(%artist);
}

package What::Discogs::Query::Release;
use Moose;
extends 'What::Discogs::Query::Base';

has 'id' => ('isa' => 'Int', is => 'rw', required => 1);

sub path {
    my $self = shift;
    return '/release/'.abs $self->id;
}

# Fetch the query, and parse an artist object from the returned xml.
sub release {
    my $self = shift;

    my %release;

    $release{query} = $self;

    my $release_xml = $self->fetch();

    my $release_parser = XML::Twig->new();

    #print {\*STDERR} "Parsing xml\n";

    $release_parser->parse($release_xml);

    my $resp_root = $release_parser->root;

    my $release_root = $resp_root->first_child('release');

    croak ("Can't find release in response; ".$self->uri) 
        if !defined($release_root);

    #print {\*STDERR} "Got release root\n";

    my $id = $self->id;
    my $title = MyUtils::get_first_text('title', $release_root);
    my $note = MyUtils::get_first_text('notes', $release_root);
    my $date = MyUtils::get_first_text('released', $release_root);
    my $country = MyUtils::get_first_text('country', $release_root);
    

    %release = (%release, (
            ( $id ? (id => $id) : ()),
            ( $title ? (title => $title) : ()),
            ( $note ? (note => $note) : ()),
            ( $date ? (date => $date) : ()),
            ( $country ? (country => $country) : ()),
        ));

    #my $db_name = MyUtils::get_first_text('', $artist_root);
    #if ($db_name =~ s/\s+ [(] ( \d+ ) [)] \z//xms) {
    #    $artist{copy_number} = $1;
    #}
    #$artist{name} = $db_name;
    
    my @genres
        = map {$_->text} 
            MyUtils::get_list('genres','genre',$release_root);
    $release{genres} = \@genres if @genres;

    my @styles
        = map {$_->text} 
            MyUtils::get_list('styles','style',$release_root);
    $release{styles} = \@styles if @styles;


    my @artists = MyUtils::get_artists($release_root);
    $release{artists} = \@artists if @artists;


    my @labels;
    my @label_nodes = MyUtils::get_list('labels','label',$release_root);
    for my $label_node (@label_nodes) {
        my $name = $label_node->{'att'}->{'name'};
        my $catno = $label_node->{'att'}->{'catno'};
        my $release_label =  Release::Label->new(
            name => $name, 
            catno => $catno,);
        push @labels, $release_label;
    }
    $release{labels} = \@labels if @labels;


    my @eas;
    my @ea_nodes 
        = MyUtils::get_list('extraartists','artist',$release_root);
    for my $ea_node (@ea_nodes) {
        my $name = MyUtils::get_first_text('name', $ea_node);
        my $copy_number;
        if ($name =~ s/\s+ [(] (\d+) [)]//xms) {
            $copy_number = $1;
        }
        my $role = MyUtils::get_first_text('roll', $ea_node);
        my $tracks = MyUtils::get_first_text('tracks', $ea_node);
        my $extra_artist =  Release::ExtraArtist->new(
            ($name ? (name => $name) : ()), 
            ($role ? (role => $role) : ()),
            ($copy_number ? (copy_number => $copy_number) : ()),
            ($tracks ? (tracks => $tracks) : ()),);
        push @eas, $extra_artist;
    }
    $release{extra_artists} = \@eas if @eas;


    my @formats;
    my @format_nodes 
        = MyUtils::get_list('formats','format',$release_root);
    for my $format_node (@format_nodes) {
        my $type = $format_node->{'att'}->{'name'};
        my $qty = $format_node->{'att'}->{'qty'};
        my @descriptions 
            = MyUtils::get_text_list(
                'descriptions', 'description', $format_node);
        my $format = Release::Format->new(
            ($type ? (type => $type) : ()),
            ($qty ? (quantity => $qty) : ()),
            (@descriptions ? (descriptions => \@descriptions) : ()),
        );
        push @formats, $format;
    }
    $release{formats} = \@formats if @formats;

    my @tracks;
    my @track_nodes 
        = MyUtils::get_list('tracklist','track',$release_root);
    for my $track_node (@track_nodes) {
        my $pos = MyUtils::get_first_text('position', $track_node);
        my $title = MyUtils::get_first_text('title', $track_node);
        my $dur = MyUtils::get_first_text('duration', $track_node);
        #print {\*STDERR} "$pos $title [$dur]\n";
        my @artists = MyUtils::get_artist_strings($track_node);

        my @track_eas;
        my @ea_nodes 
            = MyUtils::get_list('extraartists', 'artist', $track_node);
        for my $ea_node (@ea_nodes) {
            my $name = MyUtils::get_first_text('name', $ea_node);
            my $copy_number;
            if ($name =~ s/\s+ [(] (\d+) [)]//xms) {
                # TODO: Turn artists into an object and put in it.
                $copy_number = $1;
            }
            my $role = MyUtils::get_first_text('role', $ea_node);
            my $extra_artist = Release::Track::ExtraArtist->new(
                ($name ? (name => $name) : ()),
                ($role ? (role => $role) : ()),
                ($copy_number ? (copy_number => $copy_number) : ()),
            );
            push @track_eas, $extra_artist;
        }

        my $track = Release::Track->new(
            (defined $title ? (title => $title) : ()),
            (defined $dur ? (duration => $dur) : ()),
            (defined $pos ? (position => $pos) : ()),
            (@artists ? (artists => \@artists) : ()),
            (@track_eas ? (extra_artists => \@track_eas) : ()),
        );

        push @tracks, $track;
    }
    $release{tracks} = \@tracks if @tracks;

    return Release->new(%release);
}

package What::Discogs::Query::Label;
use Moose;
extends 'What::Discogs::Query::Base';

has 'name' => ('isa' => 'Str', 'is' => 'rw', required => 1);

# Replace any spaces in the name argument with a '+'.
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $rep_spaces = sub {$_[0] =~ s/\s+/+/xms};

    if ( @_ == 1 && !ref $_[0] ) {
        $rep_spaces->($_[0]->{name});
        return $class->$orig(@_);
    }
    elsif ( @_ % 2 == 0 ) {
        my %arg = @_;
        $rep_spaces->($arg{name});
        return $class->$orig(%arg);
    }
    else {
        return $class->$orig(@_);
    }
};

sub path {
    my $self = shift;
    return '/label/'.$self->name;
}

# Fetch the query, and parse an artist object from the returned xml.
sub label {
    my $self = shift;

    my %label;

    $label{query} = $self;

    my $label_xml = $self->fetch();

    my $label_parser = XML::Twig->new();

    #print {\*STDERR} "Parsing xml\n";

    $label_parser->parse($label_xml);

    my $resp_root = $label_parser->root;

    my $label_root = $resp_root->first_child('label');

    croak ("Can't find artist in response; ".$self->url) 
        if !defined($label_root);

    #print {\*STDERR} "Got label root\n";

    my $name = MyUtils::get_first_text('name', $label_root);
    my $parent = MyUtils::get_first_text('parentLabel', $label_root);
    my $contact = MyUtils::get_first_text('contactinfo', $label_root);
    my $profile = MyUtils::get_first_text('profile', $label_root);

    #if ($name =~ s/\s+ [(] ( \d+ ) [)] \z//xms) {
    #    $label{copy_number} = $1;
    #}

    $label{name} = $name if defined $name;
    $label{parent_label} = $parent if defined $parent;
    $label{contact_info} = $contact if defined $contact;
    $label{profile} = $profile if defined $profile;

    #print {\*STDERR} "Got label name\n";

    my @images 
        = map {$_->text} MyUtils::get_list('images','image',$label_root);

    my @sublabels 
        = map {$_->text} MyUtils::get_list('aliases','name',$label_root);

    my @urls
        = map {$_->text} MyUtils::get_list('urls','url',$label_root);

    my @release_roots 
        = MyUtils::get_list('releases','release', $label_root);

    for (@images, @sublabels, @urls,) {
        $_ =~ s/ (?: \s | \n )+ \z //xms;
        $_ =~ s/ \A \s+ //xms;
    }

    my @releases;

    #print {\*STDERR} "Parsing releases\n";

    for my $release_root (@release_roots) {
        my $id = $release_root->{'att'}->{'id'};
        my $title = MyUtils::get_first_text('title', $release_root);
        my $format = MyUtils::get_first_text('format', $release_root);
        my $catno = MyUtils::get_first_text('catno', $release_root);
        my $artist = MyUtils::get_first_text('artist', $release_root);

        my %label_release = (
            ($title ? (title => $title) : ()), 
            ($id ? (id => $id) : ()), 
            ($format ? (format => $format) : ()), 
            ($catno ? (catno => $catno) : ()), 
            ($artist ? (artist => $artist) : ()), 
        );

        for (values %label_release) {
            $_ =~ s/ (?: \s | \n )+ \z //xms;
            $_ =~ s/ \A \s+ //xms;
        }

        my $release = LabelRelease->new(%label_release);

        push @releases, $release;
    }

    %label = (
        %label,
        (   (@images ? (images => \@images) : ()), 
            (@sublabels ? (sublabels => \@sublabels) : ()), 
            (@urls ? (urls => \@urls) : ()), 
            (@releases ? (releases => \@releases) : ()), ),
    );

    return Label->new(%label);
}

package What::Discogs::Query::Search;
use Moose;
extends 'What::Discogs::Query::Base';

has 'type' => ('isa' => 'Str', 'is' => 'rw', default => 'all');
has 'qstr' => ('isa' => 'Str', 'is' => 'rw', required => 1);
has 'page' => ('isa' => 'Int', 'is' => 'rw', default => 1);

sub path {
    return "/search";
}

sub args {
    my $self = shift;
    my $qstr = $self->qstr;
    $qstr =~ s/(?: \A \s+) | (?: \s+ \z)//gxms;
    $qstr =~ s/\s+/+/xms;
    my %arg = ( 'f' => 'xml',
        'api_key' => $self->api,
        'q' => $qstr,
        'type' => $self->type,
        (defined $self->page ? ('page' => $self->page) : ()),
    );
    return %arg;
}

sub results {
    my $self = shift;

    my @results;
    my %result_list;
    $result_list{query} = $self;

    my $result_list_xml = $self->fetch();

    my $result_list_parser = XML::Twig->new();

    #print {\*STDERR} "Parsing xml\n";

    $result_list_parser->parse($result_list_xml);

    my $res_root = $result_list_parser->root;

    my $res_list_node = $res_root->first_child('searchresults');

    $result_list{num_results} = $res_list_node->{'att'}->{'numResults'};
    $result_list{start} = $res_list_node->{'att'}->{'start'};
    $result_list{end} = $res_list_node->{'att'}->{'end'};

    my @result_nodes
        = MyUtils::get_list('searchresults', 'result', $res_root);

    for my $node (@result_nodes) {
        my $num = $node->{'att'}->{'num'};
        my $type = $node->{'att'}->{'type'};
        my $title = MyUtils::get_first_text('title', $node);
        my $uri = MyUtils::get_first_text('uri', $node);
        my $summary = MyUtils::get_first_text('summary', $node);
        my %result = (
            number => $num,
            type => $type,
            title => $title,
            uri => $uri,
            (defined $summary ? (summary => $summary) : ()),);
        push @results, SearchResult->new(%result);
    }

    $result_list{results} = \@results;

    return SearchResultList->new(%result_list);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What::Discogs::Query
-- For contructing, executing, and parsing discogs http queries.

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

=item What::Discogs::Search

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
