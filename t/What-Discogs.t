# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
use XML::Twig;
BEGIN { use_ok('What::Discogs') };

#########################

print "Please enter a valid discogs api key:";
my $key = <STDIN>;
chomp $key;

my $query;

#######################
# Release Query Tests #
#######################
$query = What::Discogs::Query::Release->new(
    id => 59180, api => $key);

my $release = $query->release;
$query->DEMOLISH;

# TEST parsing seems succesful
ok($release->num_tracks == 6);

######################
# Artist Query Tests #
######################
$query = What::Discogs::Query::Artist->new(
    name=>"Lady Gaga", api => $key);

$artist = $query->artist;
$query->DEMOLISH;

# TEST parsing seems succesful
ok(@{$artist->realeases} > 1);

#####################
# Label Query Tests #
#####################
$query = What::Discogs::Query::Label->new(
    name=>"Interscope Records", api => $key);

$label = $query->label;
$query->DEMOLISH;

# TEST parsing seems succesful
ok($label->parent eq "Universal Music Group");

######################
# Search Query Tests #
######################
$query = What::Discogs::Query::Label->new(
    qstr="Lady Gaga", api => $key);

# TEST $result_list->all_results
my $results = $query->all_results;
$query->DEMOLISH;
ok($results->size > 20);

# TEST $result_list->filter
my $filtered_results 
    = $results->filter(sub{$_[0]->title =~ /The Fame Monster/});
ok($results->size > 0);
