use strict;
use warnings;
use Carp;

package What::Discogs::Query::Utils;

use What::XMLLib;
use What::Discogs::Artist;

sub get_urls {
    my ($node) = @_;
    return get_text_list('urls','url', $node);
}

sub get_images {
    my ($node) = @_;
    return get_text_list('images', 'image', $node);
}

sub get_artists {
    my ($node) = @_;
    my @a_nodes = get_node_list('artists', 'artist', $node);
    my @artists = map {get_first_text('name', $_)} @a_nodes;
    my $copy_number;
    for (@artists) {
        $copy_number = $_ =~ s/\s+ [(] (\d+) [)]//xms ? $1 : undef;
        $_ =~ s/\A (.*) , \s* [tT]he\z/The $1/xms;
        $_ = What::Discogs::Artist::Name->new(
            name=>$_,
            (defined $copy_number ? (copy=>$copy_number) : ()),);
    }
    return @artists;
}

sub get_artist_joins {
    my ($node) = @_;
    my @a_nodes = get_node_list('artists', 'artist', $node);
    my @joins = map {get_first_text('join', $_)} @a_nodes;
    return @joins;
}

sub get_artist_strings {
    my ($node) = @_;

    my @artists = get_artists($node);
    my @joins = get_artist_joins($node);
    #print "@joins JOIN\n";

    return if @artists == 0;

    my @artist_strings;

    my $artist_string = q{};

    while (@artists) {
        $artist_string .= shift @artists;
        my $join = shift @joins;

        if (defined $join) {
            $artist_string .= " $join ";
            next;
        }

        push @artist_strings, $artist_string;
        $artist_string = '';
    }

    push @artist_strings, $artist_string if $artist_string =~ m/./xms;
    #print "@artist_strings! FUCK!\n";

    return @artist_strings;
}

package What::Discogs::Query::Base;

use LWP::UserAgent;
use XML::Twig;
use What::XMLLib;
use What::Utils;
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
        $self->base, $self->path, '?', format_args($self->args);
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

my $null = What::Discogs::Query::Base->new(api=>'NULL');

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
use What::Discogs::Artist;
use What::XMLLib;
use What::Utils;
use Moose;
extends 'What::Discogs::Query::Base';

has 'name' => (is => "rw", required => 1);

# Replace any spaces in the name argument with a '+'.
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $rep_spaces = sub {$_[0] =~ s/\s+/+/xms};

    if ( @_ == 1 && !ref $_[0] ) {
        $_[0]->{name} =~ s/\AThe\s+(.*)\z/$1, The/xms;
        $rep_spaces->($_[0]->{name});
        return $class->$orig(@_);
    }
    elsif ( @_ % 2 == 0 ) {
        my %arg = @_;
        $arg{name} =~ s/\AThe\s+(.*)\z/$1, The/xms;
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

    my $db_name = get_first_text('name', $artist_root);

    my %copy_arg;
    if ($db_name =~ s/\s+ [(] ( \d+ ) [)] \z//xms) {
        %copy_arg = (copy=>$1)
    }

    $artist{name} = What::Discogs::Artist::Name->new(name=>$db_name,%copy_arg);

    #print {\*STDERR} "Got artist name\n";

    my @images 
        = map {$_->text} get_node_list('images','image',$artist_root);

    my @aliases 
        = map {$_->text} get_node_list('aliases','name',$artist_root);

    my @variations 
        = map {$_->text} 
            get_node_list('namevariations','name',$artist_root);

    my @members 
        = map {$_->text} get_node_list('members','name',$artist_root);

    my @urls
        = map {$_->text} get_node_list('urls','url',$artist_root);

    my @release_roots 
        = get_node_list('releases','release', $artist_root);

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
        my $title = get_first_text('title', $release_root);
        my $format = get_first_text('format', $release_root);
        my $year = get_first_text('year', $release_root);
        my $label = get_first_text('label', $release_root);
        my $track_info 
            = get_first_text('trackinfo', $release_root);

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

        my $release = What::Discogs::Artist::Release->new(%artist_release);

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

    return What::Discogs::Artist->new(%artist);
}

package What::Discogs::Query::Release;
use Carp;
use What::XMLLib;
use What::Utils;
use What::Discogs::Release;
use What::Discogs::Artist;
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
    my $title = get_first_text('title', $release_root);
    my $note = get_first_text('notes', $release_root);
    my $date = get_first_text('released', $release_root);
    my $country = get_first_text('country', $release_root);
    

    %release = (%release, (
            ( $id ? (id => $id) : ()),
            ( $title ? (title => $title) : ()),
            ( $note ? (note => $note) : ()),
            ( $date ? (date => $date) : ()),
            ( $country ? (country => $country) : ()),
        ));

    #my $db_name = get_first_text('', $artist_root);
    #if ($db_name =~ s/\s+ [(] ( \d+ ) [)] \z//xms) {
    #    $artist{copy_number} = $1;
    #}
    #$artist{name} = $db_name;
    
    my @genres
        = map {$_->text} 
            get_node_list('genres','genre',$release_root);
    $release{genres} = \@genres if @genres;

    my @styles
        = map {$_->text} 
            get_node_list('styles','style',$release_root);
    $release{styles} = \@styles if @styles;


    my @artists = What::Discogs::Query::Utils::get_artists($release_root);
    $release{artists} = \@artists if @artists;
    my @joins = What::Discogs::Query::Utils::get_artist_joins($release_root);
    $release{artist_joins} = \@joins if @joins;


    my @labels;
    my @label_nodes = get_node_list('labels','label',$release_root);
    for my $label_node (@label_nodes) {
        my $name = $label_node->{'att'}->{'name'};
        my $catno = $label_node->{'att'}->{'catno'};
        my $release_label =  What::Discogs::Release::Label->new(
            name => $name, 
            catno => $catno,);
        push @labels, $release_label;
    }
    $release{labels} = \@labels if @labels;


    my @eas;
    my @ea_nodes 
        = get_node_list('extraartists','artist',$release_root);
    for my $ea_node (@ea_nodes) {
        my $name = get_first_text('name', $ea_node);
        my $copy_number;
        my %copy_arg;
        if ($name =~ s/\s+ [(] (\d+) [)]//xms) {
            $copy_number = $1;
            %copy_arg = (copy => $copy_number);
        }
        my $ea_name = What::Discogs::Artist::Name->new(name => $name, %copy_arg);
        my $role = get_first_text('roll', $ea_node);
        my $tracks = get_first_text('tracks', $ea_node);
        my $extra_artist =  What::Discogs::Release::ExtraArtist->new(
            name => $ea_name,
            ($role ? (role => $role) : ()),
            ($tracks ? (tracks => $tracks) : ()),);
        push @eas, $extra_artist;
    }
    $release{extra_artists} = \@eas if @eas;


    my @formats;
    my @format_nodes 
        = get_node_list('formats','format',$release_root);
    for my $format_node (@format_nodes) {
        my $type = $format_node->{'att'}->{'name'};
        my $qty = $format_node->{'att'}->{'qty'};
        my @descriptions 
            = get_text_list(
                'descriptions', 'description', $format_node);
        my $format = What::Discogs::Release::Format->new(
            ($type ? (type => $type) : ()),
            ($qty ? (quantity => $qty) : ()),
            (@descriptions ? (descriptions => \@descriptions) : ()),
        );
        push @formats, $format;
    }
    $release{formats} = \@formats if @formats;

    my @tracks;
    my @track_nodes 
        = get_node_list('tracklist','track',$release_root);
    my @discs;
    my $disc_name = undef;
    my @disc_tracks;
    my $disc_num = 1;
    my $disc_title = undef;
    my %created_disc;
    my %disc_args;
    my $new_disc;
    TRACKPARSE:
    for my $track_node (@track_nodes) {
        my $pos = get_first_text('position', $track_node);
        my $title = get_first_text('title', $track_node);
        my $dur = get_first_text('duration', $track_node);

        if ($pos =~ /\A \s* \z/xms) {
            if (defined $disc_name) { 
                # If the discname was defined,  we finished parsing that disc.

                # Create a disc.
                %disc_args = (
                    (defined $disc_name ? (title => $disc_name) : ()),
                    tracks => [@disc_tracks],
                    number => $disc_num,);
                $new_disc = What::Discogs::Release::Disc->new(%disc_args);
                @disc_tracks = ();

                push @discs, $new_disc;

                # Mark that the disc has been created.
                $created_disc{$disc_num} = $new_disc;
            }
            $disc_name = $title;
            next TRACKPARSE;
        }
        elsif ($pos =~ /\A (\d+) - (\d+) \z/xms) {
            # Fetch the disc number.
            my $dno = $1;

            # Compare to the last seen disc number, $disc_num.
            if (defined $disc_num && $dno != $disc_num) {
                # Disc number just changed.
                # Create and add the last disc.
                if (!defined $created_disc{$disc_num}) {
                    # Create a disc.
                    %disc_args = (
                        (defined $disc_name ? (title => $disc_name) : ()),
                        tracks => [@disc_tracks],
                        number => $disc_num,);
                    $new_disc = What::Discogs::Release::Disc->new(%disc_args);
                    @disc_tracks = ();
                    push @discs, $new_disc;

                    # Mark that the disc has been created.
                    $created_disc{$disc_num} = $new_disc;

                    # Disc $dno has no title if we hadn't made disc $disc_num yet.
                    $disc_name = undef;
                }

                # Accept the change if it is a valid one.
                croak("Invalid disc number increase; $disc_num -> $dno")
                    if $dno != $disc_num + 1;
                $disc_num = $dno; 
            }
        } 
        elsif ($pos !~ m/\A(?: [a-zA-Z0-9]+- )? \d+\w*\z/xms && $pos !~ m/\A (?: [a-zA-Z0-9]+-)? [A-Z]+\d*\w* \z/xms) {
            # $pos should just be a number or a vinyl side+num.
            # This is mostly for debugging failure.
            croak("Can't understand track position '$pos'.");
        }

        #print {\*STDERR} "$pos $title [$dur]\n";
        my @artists = What::Discogs::Query::Utils::get_artists($track_node);
        my @joins = What::Discogs::Query::Utils::get_artist_joins($track_node);

        my @track_eas;
        my @ea_nodes 
            = get_node_list('extraartists', 'artist', $track_node);
        for my $ea_node (@ea_nodes) {
            my $name = get_first_text('name', $ea_node);
            my $copy_number;
            my %copy_arg;
            if ($name =~ s/\s+ [(] (\d+) [)]//xms) {
                %copy_arg = (copy=>$1);
            }
            my $ea_name = What::Discogs::Artist::Name->new(name=>$name, %copy_arg);
            my $role = get_first_text('role', $ea_node);
            my $extra_artist = What::Discogs::Release::Track::ExtraArtist->new(
                name => $ea_name,
                ($role ? (role => $role) : ()),
                ($copy_number ? (copy_number => $copy_number) : ()),
            );
            push @track_eas, $extra_artist;
        }

        my $track = What::Discogs::Release::Track->new(
            (defined $title ? (title => $title) : ()),
            (defined $dur ? (duration => $dur) : ()),
            (defined $pos ? (position => $pos) : ()),
            (@artists ? (artists => \@artists) : ()),
            (@joins ? (joins => \@joins) : ()),
            (@track_eas ? (extra_artists => \@track_eas) : ()),
        );
        push @disc_tracks, $track;

        push @tracks, $track;
    }
    if (@disc_tracks && !defined $created_disc{$disc_num}) {
        # Create a disc.
        %disc_args = (
            (defined $disc_name ? (title => $disc_name) : ()),
            tracks => [@disc_tracks],
            number => $disc_num,);
        @disc_tracks = ();
        $new_disc = What::Discogs::Release::Disc->new(%disc_args);
        push @discs, $new_disc;

        # Mark that the disc has been created.
        $created_disc{$disc_num} = $new_disc;
    }

    $release{tracks} = \@tracks if @tracks;
    $release{discs} = \@discs;

    return What::Discogs::Release->new(%release);
}

package What::Discogs::Query::Label;
use What::Discogs::Label;
use What::XMLLib;
use What::Utils;
use Moose;
extends 'What::Discogs::Query::Base';

has 'name' => ('isa' => 'Str', 'is' => 'rw', required => 1);

# Replace any spaces in the name argument with a '+'.
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $rep_spaces = sub {$_[0] =~ s/\s+/+/xms if $_[0]};

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

    my $name = get_first_text('name', $label_root);
    my $parent = get_first_text('parentLabel', $label_root);
    my $contact = get_first_text('contactinfo', $label_root);
    my $profile = get_first_text('profile', $label_root);

    #if ($name =~ s/\s+ [(] ( \d+ ) [)] \z//xms) {
    #    $label{copy_number} = $1;
    #}

    $label{name} = $name if defined $name;
    $label{parent} = $parent if defined $parent;
    $label{contact} = $contact if defined $contact;
    $label{profile} = $profile if defined $profile;

    #print {\*STDERR} "Got label name\n";

    my @images 
        = map {$_->text} get_node_list('images','image',$label_root);

    my @sublabels 
        = map {$_->text} get_node_list('aliases','name',$label_root);

    my @urls
        = map {$_->text} get_node_list('urls','url',$label_root);

    my @release_roots 
        = get_node_list('releases','release', $label_root);

    for (@images, @sublabels, @urls,) {
        $_ =~ s/ (?: \s | \n )+ \z //xms;
        $_ =~ s/ \A \s+ //xms;
    }

    my @releases;

    #print {\*STDERR} "Parsing releases\n";

    for my $release_root (@release_roots) {
        my $id = $release_root->{'att'}->{'id'};
        my $title = get_first_text('title', $release_root);
        my $format = get_first_text('format', $release_root);
        my $catno = get_first_text('catno', $release_root);
        my $artist = get_first_text('artist', $release_root);

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

        my $release = What::Discogs::Label::Release->new(%label_release);

        push @releases, $release;
    }

    %label = (
        %label,
        (   (@images ? (images => \@images) : ()), 
            (@sublabels ? (sublabels => \@sublabels) : ()), 
            (@urls ? (urls => \@urls) : ()), 
            (@releases ? (releases => \@releases) : ()), ),
    );

    return What::Discogs::Label->new(%label);
}

package What::Discogs::Query::Search;
use What::Discogs::Search;
use What::XMLLib;
use What::Utils;
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
        = get_node_list('searchresults', 'result', $res_root);

    for my $node (@result_nodes) {
        my $num = $node->{'att'}->{'num'};
        my $type = $node->{'att'}->{'type'};
        my $title = get_first_text('title', $node);
        my $uri = get_first_text('uri', $node);
        my $summary = get_first_text('summary', $node);
        my %result = (
            number => $num,
            type => $type,
            title => $title,
            uri => $uri,
            (defined $summary ? (summary => $summary) : ()),);
        push @results, What::Discogs::Search::Result->new(%result);
    }

    $result_list{results} = \@results;

    return What::Discogs::Search::ResultList->new(%result_list);
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
