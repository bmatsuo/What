# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('What') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $setup_err_msg
    = "Error: It doesn't look like you've run the script 'setup'. "
    . "\n    Please execute it, and then run `make test` again."
    . "\n    See 'INSTALL' or the wiki page for more information.";


ok(What->embedded_art_size_limit == 256);
my $outgoing_ok = -d What::outgoing_dir();
if (!$outgoing_ok) {
    die "\n\n$setup_err_msg\n\n\n";
}
ok( $outgoing_ok );
my $temp_wav_ok = -d What::temp_wav_dir();
if (!$temp_wav_ok) {
    die "\n\n$setup_err_msg\n\n\n";
}
ok( $temp_wav_ok );
my $temp_img_ok = -d What::temp_img_dir();
if (!$temp_img_ok) {
    die "\n\n$setup_err_msg\n\n\n";
}
ok( $temp_img_ok );
my $ice_ok = -d What::ice_dir();
if (!$ice_ok) {
    die "\n\n$setup_err_msg\n\n\n";
}
ok( $ice_ok );
ok( tracker_url =~ m!\A http://.*:\d+\z !xms )
