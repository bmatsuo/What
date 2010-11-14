package What::WhatRC;

our $VERSION = '0.0_4';

use strict;
use warnings;
use Carp;
use File::Glob 'bsd_glob';
use Data::Dumper;

use Exception::Class (
    'ValueException',
    'ArgumentException',
    'ConfigurationException',
);

use What;
use What::Format;

#use Moose;
use MooseX::Singleton;

require Exporter;
use AutoLoader qw(AUTOLOAD);
push our @ISA, qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
    whatrc
    safe_path
);

# Don't actually put your announce url in this file. Use ~/.whatrc.
has passkey => (isa => 'Str', is => 'rw', default => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
# Discogs API key (https://www.discogs.com/users/api_key).
has discogs_api_key  => (isa => 'Str', is => 'rw', default => 'xxxxxxxxx');
# The folder where music rips are placed initially.
has rip_dir => (isa => 'Str', is => 'rw', default => "~/Music/Last Rip",
        initializer => \&_init_path_attr_,);
# Root directory where uploaded files/torrents go.
has upload_root => (isa => 'Str', is => 'rw', default => "~/Music/Rips",
        initializer => \&_init_path_attr_,);
# The directory watched by your bit torrent client for new torrents.
has watch   => (isa => 'Str', is => 'rw', default => "~/Downloads",
        initializer => \&_init_path_attr_,);
# Music library root folder.
has library => (isa => 'Str', is => 'rw', default => "~/Music/Converted",
        initializer => \&_init_path_attr_,);
# If should_link_to_library is 1 hard-links are added to your music library.
has should_link_to_library => (isa => 'Str', is => 'rw', default => 0);
# The format that you prefer to add to your library (e.g. ogg, 320, v0,...).
has preferred_format => (isa => 'Str', is => 'rw', default => 'v2');
# Favorite text editor.
has editor  => (isa => 'Str', is => 'rw', default => 'nano');
# Pager used for long documents.
has pager   => (isa => 'Str', is => 'rw', default => '/usr/bin/more');

read_whatrc('~/.whatrc');

### INTERFACE SUB
# Subroutine: whatrc
# Usage: whatrc
# Returns: The whatrc instance (a shorthand for What::WhatRC->instance).
sub whatrc() {
    return What::WhatRC->instance;
}

my $dumper = Data::Dumper->new([{}],['WhatCDConfig']);

# Subroutine: 
#   release_dir(
#       artist  => $artist_name,
#       title   => $release_title,
#       year    => $release_year )
# Type: INSTANCE METHOD
# Purpose: 
#   Compute the directory that a given release will be contained in.
# Returns: 
#   A path to the release directory.
sub release_dir {
    my $self = shift;
    my %arg = @_;

    my $artist = $arg{artist} or croak("Undefined release artist.");
    my $title = $arg{title} or croak("Undefined release title.");
    my $year = $arg{year} or croak("Undefined release year.");

    my $rip_dir = $self->{rip_dir};

    my $release_dir = "$rip_dir/$artist/$artist - $year - $title";

    return $release_dir;
}

# Subroutine: $rc->announce()
# Type: INSTANCE METHOD
# Purpose: Construct a what.cd tracker announce URL for making torrents.
# Returns: URL as a string.
sub announce {
    my $self = shift;
    my $tracker = tracker_url();
    my $passkey = $self->passkey;
    my $announce = "$tracker/$passkey/announce";
    return $announce;
}

# Subroutine: $whatrc->serialize()
# Type: INSTANCE METHOD
# Purpose: 
#   Create a string representation of the RC file that can be stored in a
#   file.
# Returns: 
#   A string that represents the object on which the method was called.
sub serialize {
    my $self = shift;
    my %copy = %{$self};
    $dumper->Values([\%copy]);
    my $serial = $dumper->Dump();

    $serial =~ s/\n\s+/\n/gxms; # This should work on windows.
    $serial =~ s/\n\}/,\n}/gxms;
    return "my $serial";
}

# Subroutine: read_whatrc($config_path)
# Type: INTERFACE SUB
# Purpose: 
#   Parse a configuration file (e.g. ~/.whatrc) and initialize the 
#   What::WhatRC singleton object.
# Returns: 
#   Nothing.
sub read_whatrc {
    my $config_path = safe_path(shift);
    
    open my $config_fh, '<', $config_path
        or croak("Can't open config file $config_path\n");

    my $config_string = do {local $/; <$config_fh>};

    close $config_fh;

    my $config_ref = eval $config_string;

    if (!$@ eq '') {
        croak("Couldn't unpack rc file.\n$config_string\n$@");
    }

    my %config = %{$config_ref};

    What::WhatRC->initialize(%config);
}

### INTERNAL SUBROUTINE
# Subroutine: _init_path_attr_
# Purpose: 
#   Initializer for path attributes of the WhatRC object.
#   Makes paths 'safe'.
sub _init_path_attr_ {
    my ( $self, $value, $writer_sub_ref, $attribute_meta ) = @_;
    $writer_sub_ref->( safe_path($value) );
}

# Subroutine: safe_path($path)
# Type: INTERNAL UTILITY
# Purpose: Replace tildes '~' at the beginning of a path.
# Returns: A path with '~' replaced by user's home directory.
sub safe_path {
    my $path = shift;

    $path =~ s/(\[|\]|[{}*?])/\\$1/xms;

    my $safe = $path =~ m/~/ ? bsd_glob($path) : $path;

    return $safe;
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What - A library and program suite to accompany What.CD

=head1 SYNOPSIS

  use What;

=head1 ABSTRACT

The the What package provides several tools to facilitate uploading and
other contributions to the what.cd website.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Bryan Matsuo, E<lt>bryan.matsuo@gmail.comE<gt>

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
