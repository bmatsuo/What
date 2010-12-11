#!/usr/bin/env perl
# Use perldoc or option --man to read documentation
package What::Context;
use strict;
use warnings;
use Data::Dumper;
use What::Utils;
use What::Prompt::Choose;
use What::Subsystem;
use What;

our $VERSION = "00.00_01";
# Originally created on 12/11/10 02:40:41

require Exporter;
use AutoLoader qw(AUTOLOAD);
push our @ISA, 'Exporter';

# If you do not need this, 
#   moving things directly into @EXPORT or @EXPORT_OK will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw{
    set_context
    load_context
    rm_contexts
    context
};

use Exception::Class (
    'ContextLoadedError',
    'ContextUnloadedError',
    'ExceptionSaveError',
    'NoContextError',
    'ContextLoadError',
    'ContextYearException',
    'ContextDeleteError',);

use MooseX::Singleton;

has 'artist' => (isa => 'Str', is => 'rw', required => 1);
has 'title' => (isa => 'Str', is => 'rw', required => 1);
has 'year' => (isa => 'Str', is => 'rw', required => 1);

my $context_is_loaded = 0;
### INTERFACE SUB
# Subroutine: set_context
# Usage:
#   set_context( 
#       artist => $artist, 
#       title => $title, 
#       year => $year )
# Purpose: 
#   Ininitialize the context instance to a given release,
#       if it has not been initialized already.
# Returns: Nothing
# Throws: ContextLoadedError - Thrown if the context been set/loaded prior.
sub set_context {
    my ( %arg ) = @_;
    if ($context_is_loaded) {
        ContextLoadedError->throw(
            error => 'A context has already been set for this program.');
    }
    What::Context->initialize(%arg);
    $context_is_loaded = 1;
    return;
}

### INTERFACE SUB
# Subroutine: load_context
# Usage: load_context(  )
# Purpose: 
#   Read in a context file from the context directory and initialize
#   the class instance.
# Returns: Nothing.
# Throws: 
#   NoContextError - Thrown when no context is in the context directory.
#       load_context should always be eval'ed because of this.
#   ContextLoadError - Thrown when there is an unknown problem loading
#       the context, or if the saved context is not consistent somehow.
#   ContextLoadedError - Thrown when a context has been set/loaded prior.
sub load_context {
    if ($context_is_loaded) {
        ContextLoadedError->throw(
            error => 'A context has already been set for this program.');
    }
    my @context_paths = find_file_pattern('*.context', What::context_dir);

    my $read_context = sub {
        my $context_path = shift;
        open my $ch, '<', $context_path
            or ContextLoadError->throw(
                error => "Couldn't open $context_path");
        my $context_str = do {local $/; <$ch>};
        close $ch;

        my $context = eval 'my '.$context_str;
        if ($@ =~ m/./xms) {
            ContextLoadError->throw(error => "Parsing Error: $@");
        }
        return $context;
    };

    NoContextError->throw(error => "No context found.\n") if !@context_paths;

    my $context_path;
    my $context;
    if (@context_paths > 1) {
        my @contexts = map {$read_context->$_} @context_paths;
        my $context_p = What::Prompt::Choose->new( choices => [map {$_->to_string()} @contexts] );
        my $context_id = $context_p->prompt_user();
        $context = $contexts[$context_id];
    }
    else { $context = $read_context->($context_paths[0]); }

    What::Context->initialize( %{$context} );
    $context_is_loaded = 1;
}

### INTERFACE SUB
# Subroutine: context
# Usage: context(  )
# Purpose: Access the What::Context instance
# Returns: The What::Context instance
# Throws: 
#   ContextUnloadedError - Thrown if no context has been loaded via
#       the method load_context().
sub context() { 
    return What::Context->instance if $context_is_loaded;
    ContextUnloadedError->throw(
        error => "No context has been loaded yet."
            . "Can't use context instance.");
}
### INTERFACE SUB
# Subroutine: rm_contexts
# Usage: 
#   rm_contexts( 
#       verbose => $echo_command,
#       dry_run => $dont_execute)
# Purpose: Delete the context file from the context directory.
# Returns: Nothing
# Throws: Nothing
sub rm_contexts {
    my %arg = @_;
    my @verbose_arg = ($arg{verbose} ? (verbose => 1) : ());
    my @dry_run_arg = ($arg{dry_run} ? (dry_run => 1) : ());
    my @contexts = find_file_pattern('*.context', What::context_dir);
    return if !@contexts;
    subsystem(cmd => ['rm', @contexts], @verbose_arg, @dry_run_arg) == 0
        or ContextDeleteError->throw(
            error => "Couldn't remove contexts @contexts.");
    return;
}

### INSTANCE METHOD
# Subroutine: save
# Usage: context->save(  )
# Purpose: Write the instance out to the context directory.
# Returns: Nothing
# Throws: Nothing
sub save {
    my $self = shift;
    my $serialized = Dumper $self;
    my $output_name = "XXXXX.context";
    my $output_path = join '/', What::context_dir, $output_name;
    open my $oh, '>', $output_path
        or ExceptionSaveError->throw(error => "Couldn't open output file.");
    print {$oh} $serialized;
    close $oh;
    return;
}

### INSTANCE METHOD
# Subroutine: to_string
# Usage: context->to_string(  )
# Returns: Stringified context.
# Throws: Nothing
sub to_string {
    my $self = shift;
    my ($a, $t, $y) 
        = ($self->artist || q{}, $self->title || q{}, $self->year || q{});
    return "$a - $t ($y)";
}

return 1;
__END__

=head1 NAME

What::Context - Saved state information for What programs.

=head1 VERSION

Version 00.00_01

=head1 DESCRIPTION

=head1 AUTHOR

dieselpowered

=head1 BUGS

=over

=back

=head1 COPYRIGHT & LICENCE

(c) The What team.
