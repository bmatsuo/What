package What;

use 5.008009;
use strict;
use warnings;
use Carp;

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
	read_config
    write_config
);

our $VERSION = '0.0_2';

my %default_config = (
    # Don't actually put your announce url in this file. Use ~/.whatrc.
    'announce' => '<Your personal announce url goes here.>',
    # The folder where music rips are stored.
    'rips' => ' ~/Music/Rips',
);

# Subroutine: read_config($config_path)
# Type: INTERFACE SUB
# Purpose: 
#   Parse a configuration file (e.g. ~/.whatrc).
# Returns: 
#   A hash that describes the configuration read.
sub read_config {
    my $config_path = shift;
    
    open my $config_fh, '<', $config_path
        or croak("Can't open config file $config_path\n");

    my %config;

    my $line_count = 0;

    while (my $line = <$config_fh>) {
        $line_count += 1;
        next if $line =~ m/\A [#]/xms;
        next if $line =~ m/\A \s* \n? \z/xms;
        chomp $line;
        my ($key, $value) = split '=>', $line, 2;

        croak("Line $line_count missing '=>'\n$line\n")
            if !defined $value;

        $key =~ s/\A\s+//xms;
        $key =~ s/\s+\z//xms;
        $value =~ s/\A\s+//xms;
        $value =~ s/\s+\z//xms;

        print {\*STDERR} "$key exists in config. Overriding w/ $value.\n"
            if defined $config{$key};

        $config{$key} = $value;
    }

    close $config_fh;

    %config = (%default_config, %config);

    return %config;
}

# Subroutine: write_config($path, %config)
# Type: INTERFACE SUB
# Purpose: 
#   Write a configuration to a file.
#   Calling with no config hash causes a default configuration to be
#   printed to $path.
# Returns: 
#   Nothing.
sub write_config {
    my $path = shift;
    my %config = @_;

    open my $config_fh, '>', $path
        or croak("Couldn't open path to write configuration; $path\n");

    for my $key (%default_config) {
        my $rc_val = $config{$key};
        my $val = defined $rc_val ? $rc_val : $default_config{$key};
        print {$config_fh} "$key => $val\n";
    }

    close $config_fh;

    return;
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
