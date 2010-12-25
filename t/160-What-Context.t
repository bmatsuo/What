# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('What::Context') };

#########################

#print {\*STDERR} "Beginning test of context.\n";

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
set_context(
    artist => 'Lady Gaga',
    title => 'Born This Way',
    year => '2011');

#print {\*STDERR} What::Context->instance->to_string, "\n";

ok(context->to_string() eq 'Lady Gaga - Born This Way (2011)');
