# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('What::WhatRC') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Try to make construct a new prompt.
my $rc = What::WhatRC->new(
    announce => "deadbeef1234567890",
    rip_dir => "~",
); 

ok($rc->{'announce'} eq "deadbeef1234567890");

ok($rc->{'pager'} eq "/usr/bin/more");
