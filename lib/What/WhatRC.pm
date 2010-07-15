package What::WhatRC;

use 5.008009;
use strict;
use warnings;
use Carp;

use Data::Dumper;

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
    announce => '<Your personal announce url goes here.>',
    # The folder where music rips are stored.
    rip_dir => "$ENV{'HOME'}/Music/Rips",
    # Pager used for long documents.
    pager => '/usr/bin/more',
);

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
   bless $self, $class;
   return $self;
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
    return $serial;
}

# Subroutine: read_whatrc($config_path)
# Type: INTERFACE SUB
# Purpose: 
#   Parse a configuration file (e.g. ~/.whatrc).
# Returns: 
#   A hash that describes the configuration read.
sub read_whatrc {
    my $config_path = shift;
    
    open my $config_fh, '<', $config_path
        or croak("Can't open config file $config_path\n");

    my %default = %default_whatrc;

    my $config_string = do {local $/; <$config_fh>};

    close $config_fh;

    my $unpacked_config = eval { $config_string };

    if (!$@ eq '') {
        croak("Couldn't unpack rc file.\n$config_string");
    }

    my %config = %{$unpacked_config->[0]};

    return WhatRC->new(%config);
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
