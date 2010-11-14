# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('What::WhatRC') };

#########################

ok(-d whatrc->rip_dir);
ok(-d whatrc->upload_root);
ok(whatrc->announce =~ /./);

#ok($rc->{'pager'} eq "/usr/bin/more");
