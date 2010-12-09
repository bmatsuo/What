#!/usr/bin/env perl
package What::XMLLib;
# Use perldoc or option --man to read documentation
#

# include some core modules
use strict;
use warnings;
use XML::Twig;
use Carp;

# include CPAN modules
use Readonly;

# include any private modules
# ...

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use What::XMLLib ':all';
# If you do not need this, 
# moving things directly into @EXPORT or @EXPORT_OK will save memory.
our %EXPORT_TAGS =  ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{$EXPORT_TAGS{all}} );

our @EXPORT = qw{
    get_first_text
    get_node_list
    get_text_list
};

# Subroutine: get_first_text($tag, $node)
# Type: INTERFACE SUB
# Purpose: Easily get the text for a tag you expect only one of.
# Returns: Get the text of the first $tag child of $node.
sub get_first_text {
    my ($tag, $node) = @_;

    my $tag_node = $node->first_child($tag);

    return if !defined $tag_node;

    my $text = $tag_node->text;

    $text =~ s/\s+ \n? \z//xms;
    $text =~ s/\A \s+//xms;

    return $text;
}

# Subroutine: get_node_list($list_tag, $elt_tag, $node)
# Type: INTERFACE SUB
# Purpose: 
#   Get a list of tags that are grouped within a list tag.
# Returns: 
#   Get a list of $elt_tag nodes, children of a $list_tag node, 
#   which itself is a child of $node.
sub get_node_list {
    my ($list_tag, $elt_tag, $node) = @_;

    my $list_root = $node->first_child($list_tag);

    return if !defined $list_root;

    return $list_root->children($elt_tag);
}

# Subroutine: get_text_list($list_tag, $elt_tag, $node)
# Type: INTERFACE SUB
# Purpose: 
#   Get a list of text values for tags that are grouped within a list tag.
# Returns: 
#   Get a list of $elt_tag nodes, children of a $list_tag node, 
#   which itself is a child of $node.
sub get_text_list {
    my ($list_tag, $elt_tag, $node) = @_;
    return map {$_->text} get_node_list($list_tag, $elt_tag, $node);
}

1;
__END__

=head1 NAME

XMLLib.pm
-- short description

=head1 VERSION

Version 0.0_1
Originally created on 09/11/10 02:38:20

=head1 DESCRIPTION

=head1 AUTHOR

dieselpowered

=head1 BUGS

=over

=back

=head1 COPYRIGHT

(c) The What team
