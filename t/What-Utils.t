# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
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
