# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
use XML::Twig;
BEGIN { use_ok('What::XMLLib') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $xml_doc = <<EODOC;
<release>
    <artists>
        <artist>Iced Booyay</artist>
        <artist>Crispy Critters</artist>
    </artists>
    <title>Crunched</title>
    <year>2009</year>
    <tracks>
        <track>
            <pos>1</pos>
            <title>Iced Chili Pepper</title>
            <dur>4:02</dur>
        </track>
        <track>
            <pos>2</pos>
            <title>The Food Chain</title>
            <dur>1:35</dur>
        </track>
        <track>
            <pos>3</pos>
            <title>The Spray</title>
            <dur>2:43</dur>
        </track>
        <track>
            <pos>4</pos>
            <title>Angel Dust</title>
            <dur>1:57</dur>
        </track>
        <track>
            <pos>5</pos>
            <title>Technicolor Yawn</title>
            <dur>3:20</dur>
        </track>
    </tracks>
</release>
EODOC

my $parser = XML::Twig->new();
$parser->parse($xml_doc);
my $root = $parser->root;

# Test get_first_text
ok(What::XMLLib::get_first_text('year', $root) == 2009);

# Test get_node_list
my @tracks = What::XMLLib::get_node_list('tracks', 'track', $root);
ok(join (q{}, map {What::XMLLib::get_first_text('pos',$_)} @tracks)
    eq q{12345});

# Test get_text_list
my @artists = What::XMLLib::get_text_list('artists','artist',$root);
ok($artists[1] eq 'Crispy Critters');
