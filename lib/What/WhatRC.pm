package What::WhatRC;

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

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use what ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	read_whatrc
    safe_path
);

our $VERSION = '0.0_4';

my %default_whatrc = (
    # Don't actually put your announce url in this file. Use ~/.whatrc.
    passkey => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    # Discogs API key (https://www.discogs.com/users/api_key).
    discogs_api_key  => 'xxxxxxxxx',
    # The folder where music rips are placed initially.
    rip_dir => "$ENV{'HOME'}/Music/Last Rip",
    # Root directory where uploaded files/torrents go.
    upload_root => "$ENV{'HOME'}/Music/Rips",
    # The directory watched by your bit torrent client for new torrents.
    watch   => "$ENV{'HOME'}/Downloads",
    # Music library root folder.
    library => "$ENV{'HOME'}/Music/Converted",
    # If should_link_to_library is 1 hard-links are added to your music library.
    should_link_to_library => 0,
    # The format that you prefer to add to your library (e.g. ogg, 320, v0,...).
    preferred_format => 'v2',
    # Favorite text editor.
    editor  => 'nano',
    # Pager used for long documents.
    pager   => '/usr/bin/more',
);

my @rc_paths = qw{rip_dir pager upload_root watch library};

my $dumper = Data::Dumper->new([\%default_whatrc],['WhatCDConfig']);

# Subroutine:
#   new(
#       passkey => $whatcd_passkey,
#       discogs_api_key => $discogs_api_key,
#       rip_dir => $rip_directory,
#       upload_root => $upload_root_directory,
#       watch   => $torrent_watch_directory,
#       library => $music_library_root,
#       should_link_to_library => $user_wants_hard_links,
#       preferred_format => $users_prefered_format,
#       editor  => $text_editor,
#       pager   => $default_terminal_pager,
#       )
# Type: CLASS METHOD
# Purpose: 
#   What::WhatRC constructor.
# Returns: 
sub new { 
   my $class = shift;
   my %args = @_;
   %args = (%default_whatrc, %args);
   my $self = {};
   for my $setting (keys %default_whatrc) {
        $self->{$setting} = $args{$setting};
   }
   for my $path_setting (@rc_paths) {
        $self->{$path_setting} = safe_path($self->{$path_setting});
   }
   if (!format_is_accepted($self->{preferred_format})) {
        ValueException->throw("Invalid format $self->{preferred_format}");
   }
   bless $self, $class;
   return $self;
}

# Subroutine: library()
# Type: INSTANCE METHOD
# Purpose: 
# Returns: Nothing
sub library {
    my $self = shift;
    my $lib_path = shift;
    return $self->{library} if (!defined $lib_path);
    $self->{library} = safe_path($lib_path);
}

# Subroutine: should_link_to_library()
# Type: INSTANCE METHOD
# Purpose: 
# Returns: Nothing
sub should_link_to_library {
    my $self = shift;
    my $should_link = shift;
    return $self->{should_link} if (!defined $should_link);
    $self->{should_link} = $should_link;
}

# Subroutine: preferred_format()
# Type: INSTANCE METHOD
# Purpose: 
# Returns: Nothing
sub preferred_format {
    my $self = shift;
    my $format = shift;
    return $self->{preferred_format} if (!defined $format);
    ValueException->throw("Not valid format $format") if !format_is_accepted($format);
    $self->{preferred_format} = format_normalized($format);
}


# Subroutine: $rc->announce()
# Type: INSTANCE METHOD
# Purpose: Construct a what.cd tracker announce URL for making torrents.
# Returns: URL as a string.
sub announce {
    my $self = shift;
    my $tracker = tracker_url();
    my $passkey = $self->passkey();
    my $announce = "$tracker/$passkey/announce";
    return $announce;
}

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

# Subroutine:   $whatrc->passkey()
#               $whatrc->passkey($new_passkey)
# Type: INSTANCE METHOD
# Purpose: 
#   Setter/Accessor method for the passkey field.
# Returns: 
#   The configuration passkey (after setting, when given an argument).
# Throws:
#   ValueException if $new_passkey is not a valid What passkey.
sub passkey {
    my $self = shift;
    my $new_passkey = shift;
    return $self->{passkey} if !defined $new_passkey;
    my $valid_passkey_p = qr{ \A [0-9a-z]+ \z }xms;
    if ($new_passkey =~ m/$valid_passkey_p/xms) {
        $self->{passkey} = $new_passkey;
        return $self->{passkey};
    }
    ValueException->throw(error=>"Invalid passkey $new_passkey");
}

# Subroutine:   $whatrc->watch()
#               $whatrc->watch($new_watch_dir)
# Type: INSTANCE METHOD
# Purpose: 
#   Setter/Accessor method for the watch field.
# Returns: 
#   The configuration watch_dir (after setting, when given an argument).
# Throws:
#   ValueException if $new_watch_dir is not an existing writeable
#   directory.
sub watch_dir {
    my $self = shift;
    my $new_watch_dir = shift;
    return $self->{watch} if !defined $new_watch_dir;
    $new_watch_dir = safe_path($new_watch_dir);
    my $is_valid_watch_dir = sub {-d $_[0] && -w $_[0]};
    if ($is_valid_watch_dir->($new_watch_dir)) {
        $self->{watch_dir} = $new_watch_dir;
        return $self->{watch_dir};
    }
    ValueException->throw(error=>"No directory $new_watch_dir")
        if (!-d $new_watch_dir);
    ValueException->throw(error=>"Directory $new_watch_dir not writable.")
        if (!-w $new_watch_dir);
}

# Subroutine:   $whatrc->rip_dir()
#               $whatrc->rip_dir($new_rip_dir)
# Type: INSTANCE METHOD
# Purpose: 
#   Setter/Accessor method for the rip_dir field.
# Returns: 
#   The configuration rip_dir (after setting, when given an argument).
# Throws:
#   ValueException if $new_rip_dir is not an existing writeable
#   directory.
sub rip_dir {
    my $self = shift;
    my $new_rip_dir = shift;
    return $self->{rip_dir} if !defined $new_rip_dir;
    $new_rip_dir = safe_path($new_rip_dir);
    my $is_valid_rip_dir = sub {-d $_[0] && -w $_[0]};
    if ($is_valid_rip_dir->($new_rip_dir)) {
        $self->{rip_dir} = $new_rip_dir;
        return $self->{rip_dir};
    }
    ValueException->throw(error=>"No directory $new_rip_dir")
        if (!-d $new_rip_dir);
    ValueException->throw(error=>"Directory $new_rip_dir not writable.")
        if (!-w $new_rip_dir);
}

# Subroutine:   $whatrc->upload_root()
#               $whatrc->upload_root($new_root_dir)
# Type: INSTANCE METHOD
# Purpose: 
#   Setter/Accessor method for the upload_root field.
# Returns: 
#   The configuration upload_root (after setting, when given an argument).
# Throws:
#   ValueException if $new_root_dir is not an existing writeable
#   directory.
sub upload_dir {
    my $self = shift;
    my $new_root_dir = shift;
    return $self->{upload_root} if !defined $new_root_dir;
    $new_root_dir = safe_path($new_root_dir);
    my $is_valid_root_dir = sub {-d $_[0] && -w $_[0]};
    if ($is_valid_root_dir->($new_root_dir)) {
        $self->{upload_root} = $new_root_dir;
        return $self->{upload_root};
    }
    ValueException->throw(error=>"No directory $new_root_dir")
        if (!-d $new_root_dir);
    ValueException->throw(error=>"Directory $new_root_dir not writable.")
        if (!-w $new_root_dir);
}

# Subroutine:   $whatrc->pager()
#               $whatrc->pager($new_pager)
# Type: INSTANCE METHOD
# Purpose: 
#   Setter/Accessor method for the pager field.
# Returns: 
#   The configuration pager (after setting, when given an argument).
# Throws:
#   ValueException if $new_pager is not an executable file.
sub pager {
    my $self = shift;
    my $new_pager = shift;
    return $self->{pager} if !defined $new_pager;
    if (-x $new_pager) {
        $self->{pager} = $new_pager;
        return $self->{pager};
    }
    ValueException->throw( error=>"No file $new_pager.")
        if (!-e $new_pager);
    ValueException->throw(error=>"File $new_pager is not executable.")
        if (!-x $new_pager);
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
#   Parse a configuration file (e.g. ~/.whatrc).
# Returns: 
#   A hash that describes the configuration read.
sub read_whatrc {
    my $config_path = safe_path(shift);
    
    open my $config_fh, '<', $config_path
        or croak("Can't open config file $config_path\n");

    my %default = %default_whatrc;

    my $config_string = do {local $/; <$config_fh>};

    close $config_fh;

    my $config_ref = eval $config_string;

    if (!$@ eq '') {
        croak("Couldn't unpack rc file.\n$config_string\n$@");
    }

    my %config = %{$config_ref};

    return What::WhatRC->new(%config);
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
