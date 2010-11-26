# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('What') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(What->embedded_art_size_limit == 256);
ok( -d What::outgoing_dir() );
ok( -d What::temp_wav_dir() );
ok( -d What::temp_img_dir() );
ok( -d What::ice_dir() );
ok( tracker_url =~ m!\A http://.*:\d+\z !xms )
