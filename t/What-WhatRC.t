# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('What::WhatRC') };

#########################

my $rip_dir = whatrc->rip_dir;
#print {\*STDERR} "$rip_dir\n";
ok(-d $rip_dir);
ok(-d $upload_root);

#ok($rc->{'pager'} eq "/usr/bin/more");
