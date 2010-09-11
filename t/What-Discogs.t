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

#######################
# Release Query Tests #
#######################
my $release 
    = What::Discogs::get_release(id => 59180, api => $key);

# TEST parsing seems succesful
ok($release->num_tracks == 6);
$release->DEMOLISH;

######################
# Artist Query Tests #
######################
my $artist 
    = What::Discogs::get_artist(name=>"Lady Gaga", api => $key);

# TEST parsing seems succesful
ok(@{$artist->realeases} > 1);
$artist->DEMOLISH;

#####################
# Label Query Tests #
#####################
my $label 
    = What::Discogs::get_label(name=>"Interscope Records", api => $key);

# TEST parsing seems succesful
ok($label->parent eq "Universal Music Group");
$label->DEMOLISH;

######################
# Search Query Tests #
######################
my $result_list 
    = What::Discogs::search(qstr="Lady Gaga", api => $key);

# TEST $result_list->all_results
ok($result_list->size > 20);

# TEST $result_list->filter
my $filtered_list 
    = $result_list->filter(
        sub{$_[0]->title =~ /The Fame Monster/});

$result_list->DEMOLISH;

ok($filtered_list->size > 0);
