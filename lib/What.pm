package What;

use strict;
use warnings;
use Carp;

use What::Utils qw{:files};

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use what ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( tracker_url );

our $VERSION = '0.00_16';

my $whome = safe_path("~/.what");

my $sandbox_base = "$whome/work";
my $outgoing = "$sandbox_base/outgoing";
my $temp_wav = "$sandbox_base/wav";

my $ice_dir = "$whome/ice";

### CLASS METHOD
# Subroutine: outgoing_dir
# Usage: What::outgoing_dir(  )
# Purpose: Accessor for the path of the outgoing music directory.
# Returns: Path of the outgoing music directory.
sub outgoing_dir { return $outgoing; }

### CLASS METHOD
# Subroutine: temp_wav_dir
# Usage: What::temp_wav_dir(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub temp_wav_dir { return $temp_wav; }

### CLASS METHOD
# Subroutine: ice_dir
# Usage: What::ice_dir(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub ice_dir { return $ice_dir; }

my $tracker_url = "http://tracker.what.cd:34000";

# Subroutine: tracker_url()
# Type: INTERFACE SUB
# Purpose: Access to the 'readonly' what.cd tracker URL.
# Returns: A string copy of the url.
sub tracker_url { my $url = $tracker_url; return $url; }

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
