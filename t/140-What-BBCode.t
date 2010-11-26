# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl what.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 24;
BEGIN { use_ok('What::BBCode') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $text;

$text = "This is bold text.";
my $bold_text = bbcode->bold(text => $text);
my $exp_bold_text = "[b]This is bold text.[/b]";
ok($bold_text eq $exp_bold_text);

$text = "This is italic text.";
my $italic_text = bbcode->italic(text => $text);
my $exp_italic_text = "[i]This is italic text.[/i]";
ok($italic_text eq $exp_italic_text);

$text = "This is underlined text.";
my $underlined_text = bbcode->underlined(text => $text);
my $exp_underlined_text = "[u]This is underlined text.[/u]";
ok($underlined_text eq $exp_underlined_text);

$text = "This is strikethrough text.";
my $strikethrough_text = bbcode->strikethrough(text => $text);
my $exp_strikethrough_text = "[s]This is strikethrough text.[/s]";
ok($strikethrough_text eq $exp_strikethrough_text);

$text = "This is centered text.";
my $aligned_text = bbcode->align(justify => 'center', text => $text);
my $exp_aligned_text = '[align=center]This is centered text.[/align]';
ok($aligned_text eq $exp_aligned_text);

$text = "This is blue text.";
$colored_text = eval {bbcode->color( color => 'blue', text => $text)} || '';
my $exp_colored_text = '[color=blue]This is blue text.[/color]';
ok($colored_text eq $exp_colored_text);
$colored_text = eval {bbcode->color( code => '0000ff', text => $text)} || '';
$exp_colored_text = '[color=#0000ff]This is blue text.[/color]';
if ($@) {
    print {\*STDERR} "Error calling bbcode->color(); $@.\n";
    exit 1;
}
ok($colored_text eq $exp_colored_text);

$text = "This is size 4.";
my $sized_text = bbcode->size( scale => 4, text => $text);
my $exp_sized_text = "[size=4]This is size 4.[/size]";
ok($sized_text eq $exp_sized_text);
$text = "This is a subheader.";
my $subhead_text = bbcode->size( scale => 3, text => $text, as_subheader => 1);
my $exp_subhead_text = "===This is a subheader.===";
ok($subhead_text eq $exp_subhead_text);

$text = "google";
my $url = "http://www.google.com";
my $link1 = bbcode->link(url => $url);
my $exp_link1 = "[url]http://www.google.com[/url]";
ok($link1 eq $exp_link1);
my $link2 = bbcode->link(url => $url, text => $text);
my $exp_link2 = "[url=http://www.google.com]google[/url]";
ok($link2 eq $exp_link2);

$text = "http://marusu.channelblue.net/images/whatdotcd-l.png";
my $image = bbcode->image(url => $text);
my $exp_image = '[img=http://marusu.channelblue.net/images/whatdotcd-l.png]';
ok($image eq $exp_image);
$image = bbcode->image(url => $text, expanded => 1);
$exp_image = '[img]http://marusu.channelblue.net/images/whatdotcd-l.png[/img]';
ok($image eq $exp_image);

$text = "The quick brown fox jumps over the lazy dog.";
my $quoted_text = bbcode->quote(text => $text);
my $exp_quoted_text = "[quote]The quick brown fox jumps over the lazy dog.[/quote]";
ok($quoted_text eq $exp_quoted_text);
$quoted_text = bbcode->quote(user => 'John Doe', text => $text);
$exp_quoted_text = "[quote=John Doe]The quick brown fox jumps over the lazy dog.[/quote]";
ok($quoted_text eq $exp_quoted_text);

$text = "This is item 1";
my $item1 = bbcode->list_item( text => $text );
my $exp_item1 = "[*] This is item 1\n";
ok($item1 eq $exp_item1);
my @items = ($text, "This is item 2");
my $list = bbcode->list( @items );
my $exp_list = "[*] This is item 1\n[*] This is item 2\n";
ok($list eq $exp_list);

$text = "This is preformatted text.";
my $preformatted = bbcode->preformat(text => $text);
my $exp_preformatted = "[pre]This is preformatted text.[/pre]";
ok($preformatted eq $exp_preformatted);

$text = "LaTex";
my $latex = bbcode->latex( tex => $text );
my $exp_latex = '[tex]LaTex[/tex]';
ok($latex eq $exp_latex);

$text = "Pink Floyd";
my $artist = bbcode->artist( name => $text );
my $exp_artist = "[artist]Pink Floyd[/artist]";
ok($artist eq $exp_artist);

$text = "WhatMan";
my $user = bbcode->user( name => $text );
my $exp_user = "[user]WhatMan[/user]";
ok($user eq $exp_user);

$text = 'bbcode';
my $wiki_page = bbcode->wiki( page => $text );
my $exp_wiki_page = '[[bbcode]]';
ok($wiki_page eq $exp_wiki_page);

$text = <<EOLONG;
L
o
n
g

T
e
x
t
EOLONG
chomp $text;
my $hidden_text = bbcode->hide( text => $text );
my $exp_hidden_text = <<EOHIDDEN;
[hide]L
o
n
g

T
e
x
t[/hide]
EOHIDDEN
chomp $exp_hidden_text;
ok($hidden_text eq $exp_hidden_text);
