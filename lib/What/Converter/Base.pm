package What::Converter::Base;

use strict;
use warnings;
use Carp;
use File::Basename;
use What;
use What::Utils;
use What::Subsystem;
use What::Format::FLAC;

require Exporter;
use AutoLoader qw(AUTOLOAD);

push our @ISA, qw(Exporter);

our @EXPORT_OK = ( );

our @EXPORT = qw(
);

our $VERSION = '0.0_1';

use Moose;

has 'verbose' => (isa => 'Bool', is => 'rw', required => 0, default => 0);
has 'dry_run' => (isa => 'Bool', is => 'rw', required => 0, default => 0);

# These two attributes must be filled in be the time $c->convert() is called.
has 'flac'    => (isa => 'What::Format::FLAC', is => 'rw', required => 0);
has 'dest_dir' => (isa => 'Str', is => 'rw', required => 0);

has 'append_id' => (isa => 'Bool', is => 'rw', default => 0);
has 'id'    => (isa => 'Int', is => 'rw', required => 1);

### INSTANCE METHOD
# Subroutine: flac_path
# Usage: $self->flac_path
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub flac_path($) {
    my $self = shift;
    return $self->flac->path;
}

### INSTANCE METHOD
# Subroutine: ext
# Usage: $self->ext
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub ext($) {
    my $self = shift;
    return '';
}

### INSTANCE METHOD
# Subroutine: output_name
# Usage: $self->output_name
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub output_name($) {
    my $self = shift;
    my $name = basename($self->flac->path);
    my $ext = $self->ext();
    $name =~ s/\.flac \z/.$ext/xms;
    $name = $self->id."-$name" if $self->append_id;
    return $name;
}

# Subroutine: output_path
# Usage: $self->output_path
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub output_path($) {
    my $self = shift;
    my $d = $self->dest_dir;
    my $n = $self->output_name;
    return "$d/$n";
}

# Subroutine: $converter->options(
#   input => $lossles_path,
#   flac => $flac_path,
#   output => $lossy_path,
# )
# Type: INSTANCE METHOD
# Returns: A list of command line options to use when converting.
sub options { 
    my $self = shift;
    my %arg = @_;
    my @opts = (
        ($self->audio_quality_options()), 
        ($self->tag_options($arg{input})),
        ($self->other_options(%arg)),); 
    return @opts;
}

### INSTANCE METHOD
# Subroutine: input_precedes_opts
# Usage: $self->input_precedes_opts(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub input_precedes_opts { return 1; }

### INSTANCE METHOD
# Subroutine: copy_remaining_tags
# Usage: $converter->copy_remaining_tags(  )
# Purpose: Copy tags that aren't set with options.
# Returns: Nothing
# Throws: Nothing
sub copy_remaining_tags {
    return;
}

### INSTANCE METHOD
# Subroutine: format_descriptor
# Usage: $self->format_descriptor
# Purpose: Return a descriptor string for the format
# Returns: Nothing
# Throws: Nothing
sub format_descriptor() {
    return "";
}

### INSTANCE METHOD
# Subroutine: needs_silencing
# Usage: $self->needs_silencing(  )
# Purpose: 
# Returns: True if the converter needs to piped to /dev/null
# Throws: Nothing
sub needs_silencing {
    return 0;
}

# Subroutine: $converter->describe( )
# Type: INSTANCE METHOD
# Returns: A string describing the convertion
sub describe { 
    my $self = shift;
    my $desc = join q{ }, 
        "Encoded from FLAC (100% log) using", 
        $self->program_description(),
        "with options",
        $self->tag_options(), ;
    $desc .= '.';
    return $desc;
}

### INSTANCE METHOD
# Subroutine: can_embed_img
# Usage: $converter->can_embed_img(  )
# Purpose: 
#   Return value of proposition 
#   "$converter can embed an image in its products".
# Returns: Boolean.
# Throws: Nothing
sub can_embed_img { return 0; }

### INSTANCE METHOD
# Subroutine: image_options
# Usage: $self->image_options(  )
# Purpose: 
#   Create a list of command line options for setting the image in product files.
# Returns: Nothing
# Throws: Nothing
sub image_options { return (); }

### INSTANCE METHOD
# Subroutine: create_temp_image
# Usage: $converter->create_temp_image( $flac )
# Purpose: Create a temporary exported copy of $flac's image.
# Returns: The path to the temporary image.
# Throws: Nothing
sub create_temp_image {
    my $self = shift;
    my $flac = $self->flac;
    my $img_info = $flac->image_info();
    return if !defined $img_info;

    my $temp_path = $self->temp_img_path();

    open my $temp_img, ">", $temp_path
        or croak("Couldn't open temporary image; $temp_path");
    print {$temp_img} $img_info->{imageData};
    close $temp_img;

    return $temp_path;
}

### INSTANCE METHOD
# Subroutine: temp_img_path
# Usage: $converter->temp_img_path(  )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub temp_img_path {
    my $self = shift;
    my $flac = $self->flac;
    my $img_info = $flac->image_info();
    return if !defined $img_info;
    my $type = $img_info->{mimeType};


    my $temp_name = $self->id;

    my $ext;
    if ($type eq 'image/jpeg') { $ext = 'jpg'; }
    elsif ($type eq 'image/png') { $ext = 'png'; }
    else { croak("Unrecognized image type; $type."); }

    $temp_name .= ".$ext";
    my $temp_path = What::temp_img_dir;
    $temp_path .= "/$temp_name";
    return $temp_path;
}

# Subroutine: $converter->convert(
#   wav => $wav_path,
#   [flac => $flac_path],
# )
# Type: INSTANCE METHOD
# Purpose: 
#   Create a converted audio file with tags from $flac_path.
#   Some converters may require a WAVE file.
# Returns: Nothing.
sub convert { 
    my $self = shift;
    my %arg = @_;

    #die "Testing death" if $self->id == 9;

    # Check FLAC existence.
    my $flac 
        = $arg{flac} ? $self->flac($arg{flac}) 
        : $self->flac;

    if (!defined $flac) {
        croak("No What::Format::FLAC given for conversion.\n");
    }

    if (!$flac->isa('What::Format::FLAC')) {
        croak("Input is not a What::Format::FLAC object; $flac");
    }

    my $output = $self->output_path;
    if (!defined $output) { croak("Output path is not defined."); }

    my $output_dir = dirname($output);
    if (!-d $output_dir) {
        croak("Directory of output path does not exist; $output_dir");
    }

    # Check WAVE if necessary
    my $wav = $arg{wav};
    if ($self->needs_wav()) {
        if (!defined $wav) {
            croak("WAVE file not given.");
        }
        if ($wav !~ m/\.wav\z/xms) {
            croak("wav argument is not a WAVE file; $wav");
        }
        if (!-e $wav) {
            croak("WAVE file does nat exist; $wav");
        }
    }

    # Set the converter input.
    $arg{input} = $self->needs_wav() ? $wav : $flac->path;

    # Export any images.
    my $temp_img = $self->temp_img_path;
    my $have_img = $self->can_embed_img && $temp_img;
    if ($have_img) {
        $self->create_temp_image();
    }

    # Perform the conversion.
    my @cmd = ($self->options(%arg));
    if ($have_img) {
        push @cmd, $self->image_options();
    }
    if ($self->input_precedes_opts()) { 
        unshift @cmd, $arg{input};
    }
    else {
        push @cmd, $arg{input};
    }
    unshift @cmd, $self->program();
    my $res = subsystem(
        cmd => \@cmd,
        verbose => $self->verbose(),
        dry_run => $self->dry_run(),
        #($self->needs_silencing() ? (redirect_to => '/dev/null') : ()), #This didn't work...
    );

    # Destroy the WAVE if necessary.
    #if ($self->needs_wav()) {
    #    my $rm_res = subsystem(
    #        cmd => ['rm', $wav],
    #        verbose => $self->verbose(),
    #        dry_run => $self->dry_run(),);
    #    if ($rm_res != 0) {
    #        croak("Couldn't remove temporary WAVE file; $wav");
    #    }
    #}
    
    # Check that the conversion went smoothly.
    if ($res != 0) {
        croak("Couldn't convert;\n$arg{input}   ->   $output\n$?");
    }

    # Delete temprorary image.
    if ($have_img) {
        $res = subsystem(
            cmd => ['rm', $temp_img],
            verbose => $self->verbose(),
            dry_num => $self->dry_run(),
        );

        if ($res != 0) {
            croak("Couldn't remove temprorary image.\n");
        }
    }

    $self->copy_remaining_tags();

    return;
}

# Methods to override in subclasses

# Subroutine: $converter->needs_wav()
# Type: INSTANCE METHOD
# Returns: 
#   A true boolean context if the converter needs a WAVE audio file.
sub needs_wav { return 1; }

# Subroutine: $converter->program()
# Type: INSTANCE METHOD
# Returns: The converting program used be the coverter.
sub program { return ""; }

# Subroutine: $converter->program_description()
# Type: INSTANCE METHOD
# Returns: A string naming the program and version number.
sub program_description { return ""; }

# Subroutine: $converter->audio_quality_options()
# Type: INSTANCE METHOD
# Returns: 
#   A list of command line options used that control quality (bitrate).
sub audio_quality_options { return (); }

# Subroutine: $converter->tag_options(flac => $flac_path)
# Type: INSTANCE METHOD
# Returns: 
#   A list of command line options used that set tags.
sub tag_options { return (); }

# Subroutine: $converter->other_options(
#   input => $lossles_path,
#   flac => $flac_path,
#   output => $lossy_path,
# )
# Type: INSTANCE METHOD
# Purpose:
#   Some options, such as silencing, may not fit into other categories, 
#   so they can go here.
# Returns: 
#   A list of other command line options used in converting.
sub other_options { return (); }

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

What - A library and program suite to accompany What.CD

=head1 SYNOPSIS

This class is not to be used directly but is to be inherited from.

=head1 ABSTRACT

This class is a base class from audio converters. 
They are used to take a FLAC file and covert it to another format 
at a specified path.

=head1 SEE ALSO

What::Converter::MP3
What::Converter::OGG
What::Converter::AAC

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
