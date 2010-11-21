# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';


use Test::More tests => 9;
use XML::Twig;

# Get a discogs API key from the user.
print {\*STDERR} "Please enter a valid discogs api key:";
my $key = <STDIN>;
die "Couldn't parse API key (must be alphanumeric); $key"
    if ($key !~ s/\A \s* ([a-z0-9]+) \s*\n? \z/$1/xms);

BEGIN { use_ok('What::Discogs') };

#######################

#######################
# Release Query Tests #
#######################
my $release = get_release(id => 59180, api => $key);
ok($release->num_tracks == 6);

# Get a two disc release and check the number of tracks.
$release = get_release(id => 2043326, api => $key);
ok($release->num_tracks == 22);
ok($release->disc(1)->title eq 'The Fame Monster');

######################
# Artist Query Tests #
######################
my $artist 
    = get_artist(name=>"Dr. Dre", api => $key);

# TEST parsing seems succesful
ok(@{$artist->releases} > 1);

#####################
# Label Query Tests #
#####################
my $label 
    = get_label(name=>"Interscope Records", api => $key);

# TEST parsing seems succesful
ok($label->parent eq "Universal Music Group");

######################
# Search Query Tests #
######################
my $result_list 
    = search(qstr=>"Lady Gaga", api => $key);

# TEST $result_list->all_results
ok($result_list->num_results > 20);

my $double = $result_list->dup();
ok($double->num_results > 20);

# TEST $result_list->filter
my $filtered_list 
    = $result_list->grep(
        sub{my $x = shift; $x->type eq 'release'});#&& $x->title =~ /The Fame/i});

#print {\*STDERR}
#    map {($_->type eq 'release' ? $_->title : $_->type)."\n"} 
#        @{$filtered_list->results};

my $num_res = $filtered_list->num_results;

#print {\*STDERR} "$num_res RESULTS FILTERED\n";

ok($filtered_list->num_results < $result_list->num_results);
