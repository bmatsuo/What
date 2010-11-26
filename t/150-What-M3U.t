# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('What::M3U') };

#########################

#mkdummyinfo($length,$trackno,$artist,$title)
sub mkdummyinfo {
    my ($length, $track_num, $artist, $title) = @_;
    my $track = {
        trackTotalLengthSeconds => $length, 
        tags => {
            TRACKNUMBER => $track_num,
            artist => $artist,
            title => $title,},
    };
    return $track;
}

my $dummy_release = {
    '/blah/01 Fixies.flac' 
        => mkdummyinfo(123,1,'Hipster Duo','Fixies'),
    '/blah/02 Retro Shades.flac' 
        => mkdummyinfo(231,2,'Hipster Duo','Retro Shades'),
    '/blah/03 Skinny Jeans.flac' 
        => mkdummyinfo(312,3,'Hipster Duo','Skinny Jeans'),
};

my $expected_m3u=<<EOM3U;
#EXTM3U
#EXTINF:123,Fixies
01 Fixies.flac
#EXTINF:231,Retro Shades
02 Retro Shades.flac
#EXTINF:312,Skinny Jeans
03 Skinny Jeans.flac
EOM3U

ok($expected_m3u eq mkm3u_info(info=>$dummy_release));

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

