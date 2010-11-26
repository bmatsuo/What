# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('What::Format') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Test format_normalized.
ok(format_normalized('OgG') eq 'OGG');

# Test format_is_accepted.
ok(format_is_accepted('OGG'));
ok(format_is_accepted('aac'));
ok(format_is_accepted('flAC'));
ok(!format_is_accepted('mp3'));

# Test format_extension
ok(format_extension('AAC') eq 'm4a');
ok(!defined format_extension('MP3'));
ok(!format_extension('m4a'));
