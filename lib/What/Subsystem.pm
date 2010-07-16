package What::Subsystem;

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
    subsystem
);

our $VERSION = '0.0_1';

my %def_arg = ( dryrun => 0, verbose => 0 );

# Subroutine: 
#   What::Subsystem->new(
#       dryrun => $is_dryrun, 
#       verbose => $is_verbose,)
# Type: CLASS METHOD
# Purpose: Create a What::Subsystem object.
#   The constructor takes two optional arguments.
#   If $is_dryrun evaluates true, then the system command is not
#   executed.
#   If $is_verbose evaluates true, then the system command will be
#   printed to STDOUT before it is executed.
# Returns:
#   New What::Subsystem object.
sub new {
    my $class = shift;
    my %arg = @_;
    %arg = (%def_arg, %arg);
    my $self = {dryrun=>$arg{dryrun}, verbose=>$arg{verbose}};
    bless $self, $class;
    return $self;
}

# Subroutine:   $subsystem->exec(@cmd)
#               $subsystem->exec($cmd)
# Type: INSTANCE METHOD
# Purpose: 
#   Make a system command using the options of $subsystem.
# Returns: 
#   The exitcode of the system call, or 0 if $subsystem->{dryrun}
#   is true
sub exec {
    my $self = shift;
    my @cmd = @_;
    if (@cmd > 1) {
        print "@cmd\n" if $self->{verbose};
        return system @cmd if not $self->{dryrun};
    }
    else {
        my $cmd = $cmd[0];
        print "$cmd\n" if $self->{verbose};
        return system "$cmd" if not $self->{dryrun};
    }
    return 0;
}

# Subroutine: 
#   subsystem(
#       cmd => $cmd,
#       dryrun => $is_dryrun, 
#       verbose => $is_verbose,) 
# Type: INTERFACE SUB
# Purpose: Perform a subsystem call without creating an object first.
#   $cmd can be either a string or an ARRAY reference.
# Returns: 
#   The exitcode of $cmd, or 0 if $is_dryrun.
sub subsystem {
    my %arg = @_;
    my $cmd = $arg{cmd};
    my ($is_dryrun, $is_verbose) = ($arg{dryrun}, $arg{verbose});
    if ("ARRAY" eq ref $cmd) {
        my @cmd = @$cmd;
        print "@cmd\n" if $is_verbose;
        return system @cmd if not $is_dryrun;
    }
    else {
        print "$cmd\n" if $is_verbose;
        return system "$cmd" if not $is_dryrun;
    }
    return 0;
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
