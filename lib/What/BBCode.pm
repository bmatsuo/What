#!/usr/bin/env perl
# Use perldoc or option --man to read documentation
#
package What::BBCode;
use MooseX::Singleton;

has 'img_style' # If not "expanded", the short image format [img=<url>] is used.
    => (isa => 'Str', is => 'rw', default => 'compact');

our $VERSION = "00.00_01";
# Originally created on 11/24/10 16:43:47

use strict;
use warnings;

use Exception::Class ('BBCodeException');

require Exporter;
use AutoLoader qw(AUTOLOAD);
push our @ISA, 'Exporter';

# If you do not need this, 
#   moving things directly into @EXPORT or @EXPORT_OK will save memory.
#our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw{bbcode};

### INTERFACE SUB
# Subroutine: bbcode
# Usage: bbcode
# Purpose: Accessor to the singleton What::BBCode object.
# Returns: Nothing
# Throws: Nothing
sub bbcode() { return What::BBCode->instance; }

### INSTANCE METHOD
# Subroutine: size
# Usage: 
#   $self->size( 
#       scale => $scale, 
#       text => $text, 
#       [as_subheader => $looks_like_subheader])
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub size {
    my $self = shift;
    my $scale = 2;
    my $text = "";
    my (%arg) = @_;
    $scale = $arg{scale} if $arg{scale};
    $text = $arg{text} if $arg{text};
    if ($scale !~ /\A \d \z/xms) { # Scale is between 1 and 7 (inclusive).
        BBCodeException->throw(
            error => "Scale must be an integer in range [1,7]; '$scale'.");
    }
    if ($scale == 0 || $scale > 7) {
        BBCodeException->throw(
            error => "Scale must be in range [1,7]; $scale.");
    }
    if ($arg{as_subheader}) {
        return "=$text=" if $scale == 1;
        return join q{}, 
            '=', $self->size( (%arg, (scale => $scale - 1)) ), '=';
    }
    return _mktag_(tag => 'size', val => $scale, inner => $text);
}

### INSTANCE METHOD
# Subroutine: color
# Usage: 
#   $self->color( name => $color_name, text => $text)
#   $self->color( code => $color_hex_code, text => $text);
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub color {
    my $self = shift;
    my (%arg) = @_;
    my $name = $arg{color};
    my $code = $arg{code};
    my $text = $arg{text} || "";

    if (defined $name) {
        if ($name =~ /\p{isAlpha}+/ixms) {
            return _mktag_(tag => 'color', val => $name, inner => $text);
        }
        else {
            BBCodeException->throw(
                error => "Color name not a string of latin letters; '$name'.");
        }
    }

    if (defined $code) {
        if ($code =~ /\p{xdigit}{6}/xms) {
            return _mktag_(tag => 'color', val => "#$code", inner => $text);
        }
        else {
            BBCodeException->throw(
                error => "Color code not a string of 6 hex digits; '$code'.");
        }
    }

    BBCodeException->throw(
        error => "Niether color name, nor color code defined.");
}

### INSTANCE METHOD
# Subroutine: quote
# Usage: 
#   $self->quote( 
#       user => $username, 
#       text => $quote_text )
# Purpose: 
#   Create a quoted markup string.
#   When the user is not defined, a simple blockquote is made.
#   The 'text' defaults to the empty string "".
# Returns: A string containing a BBCode quote.
# Throws: Nothing
sub quote {
    my $self = shift;
    my $user;
    my $text = q{};
    my (%arg) = @_;
    $user = $arg{user} if $arg{user};
    $text = $arg{text} if $arg{text};
    return _mktag_(
        tag => 'quote',
        (defined $user ? (val => $user) : ()),
        inner => $text );
}

### INSTANCE METHOD
# Subroutine: align
# Usage: 
#   $self->align( 
#       justify => $left_right_center, 
#       text => $text )
# Purpose: 
#   Create an aligned markup string.
#   The default alignment is "left", an the default text is "".
# Returns: Nothing
# Throws: Nothing
sub align {
    my $self = shift;
    my $justify = "left";
    my $text = "";
    my ( %arg ) = @_;
    $text = $arg{text} if $arg{text};
    if ($arg{justify}) {
        # Check that justify is either 'left', 'right', or 'center'.
        $justify = $arg{justify};
        if ($justify !~ /(?: left | right | center )/ixms) {
            BBCodeException->throw(error => "Invalid justification $justify.");
        }
    }

    return _mktag_( tag => 'align', val => $justify, inner => $text);
}

### CLASS METHOD
# Subroutine: link
# Usage: 
#   What::BBCode->link( 
#       url => $url, 
#       [text => $text] )
# Purpose: Create a link markup string. The default text is "link".
# Returns: A BBCode link.
# Throws: Nothing
sub link {
    my $class = shift;
    my %arg = @_;
    my $url = $arg{url};
    my $text = $arg{text};
    my $link = _mktag_( 
        tag => 'url', 
        ($text ? (val => $url) : ()), 
        inner => $text || $url,);
    return $link;
}

### INSTANCE METHOD
# Subroutine: image
# Usage: 
#   bbcode->image( 
#       url => $url, 
#       [expanded => $use_long_format] )
# Purpose: 
#   Create an image markup string. 
#   The image format defaults to bbcode->img_style.
# Returns: Nothing
# Throws: Nothing
sub image {
    my $self = shift;
    my ( %arg ) = @_;
    my $url = $arg{url};
    my $exp_arg = $arg{expanded};
    my $expanded = $self->img_style;
    $expanded = 'expanded' if $exp_arg;
    return _mktag_( tag => 'img', inner=> $url ) if $expanded eq 'expanded';
    return _start_('img', $url );
}

### INSTANCE METHOD
# Subroutine: bold
# Usage: $self->bold( text => $inner_bbcode )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub bold {
    my $self = shift;
    my $text = "";
    my ( %arg ) = @_;
    $text = $arg{text} if $arg{text};
    return _mktag_(
        tag => 'b',
        inner => $text);
}

### INSTANCE METHOD
# Subroutine: italic
# Usage: $self->italic( text => $inner_bbcode )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub italic {
    my $self = shift;
    my $text = "";
    my ( %arg ) = @_;
    $text = $arg{text} if $arg{text};
    return _mktag_(
        tag => 'i',
        inner => $text);
}

### INSTANCE METHOD
# Subroutine: underlined
# Usage: bbcode->underlined( text => $inner_bbcode )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub underlined {
    my $self = shift;
    my $text = "";
    my ( %arg ) = @_;
    $text = $arg{text} if $arg{text};
    return _mktag_(
        tag => 'u',
        inner => $text);
}

### INSTANCE METHOD
# Subroutine: strikethrough
# Usage: bbcode->strikethrough( text => $inner_bbcode )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub strikethrough {
    my $self = shift;
    my $text = "";
    my ( %arg ) = @_;
    $text = $arg{text} if $arg{text};
    return _mktag_(
        tag => 's',
        inner => $text);
}

### INSTANCE METHOD
# Subroutine: list_item
# Usage: $self->list_item( text => $text )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub list_item {
    my $self = shift;
    my $text = "";
    my (%arg) = @_;
    $text = $arg{text} if $arg{text};
    return _start_('*') . " $text\n";
}

### INSTANCE METHOD
# Subroutine: list
# Usage: $self->list( @items )
# Purpose: Turn a list of strings into a BBCode list.
# Returns: Nothing
# Throws: Nothing
sub list {
    my $self = shift;
    my (@items) = @_;
    return join q{}, (map { $self->list_item( text => $_ ) } @items);
}

### INSTANCE METHOD
# Subroutine: preformat
# Usage: $self->preformat( text => $text )
# Purpose: Create a preformatted block of text.
# Returns: Nothing
# Throws: Nothing
sub preformat {
    my $self = shift;
    my $text = "";
    my (%arg) = @_;
    $text = $arg{text} if $arg{text};
    return _mktag_(tag => 'pre', inner => $text);
}

### INSTANCE METHOD
# Subroutine: latex
# Usage: $self->latex( tex => $source_code )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub latex {
    my $self = shift;
    my $tex = "";
    my (%arg) = @_;
    $tex = $arg{tex} if $arg{tex};
    return _mktag_(tag => 'tex', inner => $tex);
}

### INSTANCE METHOD
# Subroutine: artist
# Usage: $self->artist( name => $artist_name )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub artist {
    my $self = shift;
    my (%arg) = @_;
    my $name = $arg{name};
    if (!defined $name) {
        BBCodeException->throw(error=>'Artist name not defined.');
    }
    return _mktag_(tag => 'artist', inner => $name);
}

### INSTANCE METHOD
# Subroutine: user
# Usage: $self->user( name => $username )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub user {
    my $self = shift;
    my (%arg) = @_;
    my $name = $arg{name};
    if (!defined $name) {
        BBCodeException->throw(error=>'Username not defined.');
    }
    return _mktag_(tag => 'user', inner => $name);
}

### INSTANCE METHOD
# Subroutine: wiki
# Usage: $self->wiki( page => $pagename )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub wiki {
    my $self = shift;
    my (%arg) = @_;
    my $page = $arg{page};
    if (!defined $page) {
        BBCodeException->throw(error => 'Wiki page name not defined.');
    }
    return _start_(_start_($page));
}

### INSTANCE METHOD
# Subroutine: hide
# Usage: $self->hide( label => $label_text, text => $text )
# Purpose: Create markup that is hidden by default.
# Returns: Nothing
# Throws: Nothing
sub hide {
    my $self = shift;
    my $label;
    my $text = "";
    my (%arg) = @_;
    $label = $arg{label};
    $text = $arg{text} if $arg{text};
    return _mktag_(
        tag => 'hide', 
        (defined $label ? (label => $label) : ()),
        inner => $text);
}

### INTERNAL UTILITY
# Subroutine: _mktag_
# Usage: 
#   _mktag_( 
#       tag   => $tag,
#       val   => $val,
#       inner => $inner_bbcode, )
# Purpose: Create
# Returns: Nothing
# Throws: Nothing
sub _mktag_ {
    my (%arg) = @_;

    my    ( $tag,      $val,      $inner)
        = ( $arg{tag}, $arg{val}, $arg{inner});

    return join q{}, _start_($tag, $val), $inner || q{}, _end_($tag);
}

### INTERNAL UTILITY
# Subroutine: _start_
# Usage: _start_( $tag [, $val ] )
# Purpose: Start a markup section (e.g. "[quote=dieselpowered]").
# Returns: Nothing
# Throws: Nothing
sub _start_ {
    my ($tag, $val) = @_;
    my $insert 
        = $val && $val =~ /./xms ?  "=$val"
        : q{};
    return "[$tag$insert]";
}

### INTERNAL UTILITY
# Subroutine: _end_
# Usage: _end_( $tag )
# Purpose: 
# Returns: Nothing
# Throws: Nothing
sub _end_ {
    my ($tag) = @_;
    return "[/$tag]";
}

return 1;

__END__

=head1 NAME

BBCode - Module for creating BBCode markup.

=head1 VERSION

Version 00.00_01

=head1 DESCRIPTION

What::BBCode is a module for generating BBCode markup strings.
It will be kept up to date with the functionality described at the wiki page

    https://ssl.what.cd/wiki.php?action=article&id=23
    or http://what.cd/wiki.php?action=article&id=23

=head1 EXAMPLES

    my $quote = bbcode->quote( 
            user => 'dieselpowered'
            text => join "\n",
                "This is an example BBCode string.",
                "For more info about BBCode, see "
                    . bbcode->link( 
                        url => 'http://what.cd/wiki.php?action=article&id=23',
                        text => 'this wiki article'),
                q{}
    );
    
    print "$quote\n";

The above code will print the string

    This is an example BBCode string.
    For more info about BBCode, see <this wiki article>.

Where <this wiki article> is actually a hyper link with text "this wiki article".

=head1 AUTHOR

Bryan Matsuo [bryan.matsuo@gmail.com]

=head1 BUGS

There is no way to 'trigger' markup tags. 
That is, no way to generate a vesion of the string that will not actually get marked up.
This is implemented with the "[n]" tag in BBCode.

=over

=back

=head1 COPYRIGHT & LICENCE

(c) Bryan Matsuo [bryan.matsuo@gmail.com]
