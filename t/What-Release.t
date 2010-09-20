# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('What::Release') };

my $release = What::Release->new(
    rip_root => "~",
    artist => "Lady Gaga", 
    title => "The Fame Monster", 
    year => "2009");

my $release_dir = $release->dir("/home/bryan");

ok( $release_dir 
    eq '/home/bryan/Lady Gaga/Lady Gaga - The Fame Monster (2009)')

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

