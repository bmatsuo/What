# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('What::Utils', qw{ :all }) };

#########################

ok(glob_safe('/blah*/what? [FLAC]') eq '/blah\*/what\? \[FLAC\]');

my @files = find_hierarchy('.');

# As of writing this test, there were 46 files in MANIFEST
ok(@files > 40);

my $fake_flac = {
    tags => { # I'm thinking about this one a lot lately.
        'ALBUM' => 'Pink Friday',
        'artist' => 'Nicki Minaj',
        'Title' => 'Right Thru Me',
        'Year' => '2010',},
};
my $artist = get_flac_tag($fake_flac, 'ARTIST');
ok($artist eq 'Nicki Minaj');
my ($title, $album) = get_flac_tags($fake_flac, qw{title album});
ok($title eq 'Right Thru Me');
ok($album eq 'Pink Friday');

my $illegal_name = "AC/DC?";
ok(has_bad_chars($illegal_name));
ok('AC_DC_' eq replace_bad_chars($illegal_name));
my $bad_chars = bad_chars($illegal_name);
ok($bad_chars eq '/?' || $bad_chars eq '?/');
