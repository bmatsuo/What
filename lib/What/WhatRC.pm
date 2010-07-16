package What::WhatRC;

use 5.008009;
use strict;
use warnings;
use Carp;

use Data::Dumper;

use Exception::Class (
    'ValueException',
    'ArgumentException',
    'ConfigurationException',
);

use What;

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
);

our $VERSION = '0.0_4';

my %default_whatrc = (
    # Don't actually put your announce url in this file. Use ~/.whatrc.
    passkey => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    # The folder where music rips are stored.
    rip_dir => "$ENV{'HOME'}/Music/Rips",
    # Pager used for long documents.
    pager   => '/usr/bin/more',
);

my @rc_paths = qw{rip_dir pager};

my $dumper = Data::Dumper->new([\%default_whatrc],['WhatCDConfig']);

# Subroutine:
#   new(
#       announce => $annource_url,
#       rip_dir => $rip_root_directory,
#       pager   => $default_terminal_pager,)
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
   bless $self, $class;
   return $self;
}

# Subroutine: $rc->announce()
# Type: INSTANCE METHOD
# Purpose: Construct a what.cd tracker announce URL for making torrents.
# Returns: URL as a string.
sub announce {
    my $self = shift;
    my $tracker = tracker_url();
    my $passkey = $self->passkey();
    my $announce = "$tracker/$passkey";
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
    $path =~ s! \A ~ ([^/]+)? !
        $1  ? [getpwnam($1)]->[7]
            : ($ENV{HOME} || $ENV{LOGDIR} || [getpwuid($>)]->[7])
    !exms;
    return $path;
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

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
