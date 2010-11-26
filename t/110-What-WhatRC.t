# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('What::WhatRC') };

#########################

my $config_err_msg 
    = "ERROR: The file '~/.whatrc' does not look properly configured!";
 

ok(-d whatrc->rip_dir);

ok(-d whatrc->upload_root);

ok(-d whatrc->library);

my $passkey = whatrc->passkey;
# Make sure the user has set their passkey.
my $passkey_is_good = $passkey !~ /\A x+ \z/ixms;
if (!$passkey_is_good) {
    my $passkey_err = join q{}, "\n\n",
        "$config_err_msg\n\n",
        "** If your passkey really is a string of X's, just     **\n",
        "** temporary change it (e.g. make it 'xxxxxxxxx1').    **\n",
        "** Then run `make test`, and change your passkey back. **\n",
        "\n\n";
    die $passkey_err;
}

ok(whatrc->announce =~ /./);
