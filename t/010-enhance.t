#!perl -T
use strict;
use warnings;
use Test::More tests => 14;
use Test::MockObject;
use Test::Exception;

use NetHack::Menu;

my @rows_returned;
my @rows_checked;
sub row_plaintext {
    my $self = shift;
    push @rows_checked, shift;
    return '' if $rows_checked[-1] == 0;
    shift @rows_returned;
}

sub checked_ok {
    my $rows = shift;
    my $name = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is_deeply(\@rows_checked, $rows, $name);
    @rows_checked = ();
}

my $vt = Test::MockObject->new;
$vt->mock(row_plaintext => \&row_plaintext);
$vt->set_always(rows => 24);
$vt->set_isa('Term::VT102');

my $menu = NetHack::Menu->new(vt => $vt, select_count => 'single');

is(@rows_checked, 0, "No rows checked yet.");

push @rows_returned, split /\n/, (<< 'MENU') x 3;
 Pick a skill to advance:

 Fighting Skills
       bare handed combat [Unskilled]
       riding             [Unskilled]
 Weapon Skills
       dagger             [Unskilled]
       knife              [Unskilled]
       axe                [Unskilled]
       short sword        [Unskilled]
       club               [Unskilled]
       mace               [Unskilled]
 a -   quarterstaff       [Basic]
       polearms           [Unskilled]
       spear              [Unskilled]
       javelin            [Unskilled]
       trident            [Unskilled]
       sling              [Unskilled]
       dart               [Unskilled]
       shuriken           [Unskilled]
 Spellcasting Skills
       attack spells      [Basic]
       healing spells     [Unskilled]
 (1 of 2)
MENU

ok($menu->has_menu, "we has a menu");
checked_ok([0..24], "rows 0-23 checked for finding the end");

ok(!$menu->at_end, "it knows we're NOT at the end");
checked_ok([0..24, 0..23], "rows 0-5 checked for finding the end, 0-4 checked for items");
is($menu->next, '>', "next page");
like(shift(@rows_returned), qr/^\s*\(1 of 2\)\s*$/, "last row to be returned is our 'end of menu indicator");
is(@rows_returned, 0, "no more rows left");

push @rows_returned, split /\n/, (<< 'MENU') x 2;
       divination spells  [Unskilled]
       enchantment spells [Basic]
       clerical spells    [Unskilled]
       escape spells      [Unskilled]
       matter spells      [Unskilled]
 (2 of 2)
MENU

ok($menu->at_end, "NOW we're at the end");
checked_ok([0..6, 0..5], "rows 0-5 checked for finding the end, 0-4 checked for items");
dies_ok { $menu->next } "next after end dies";

my @items_selectable;
my @selectors;
$menu->select(sub {
    push @items_selectable, $_;
    push @selectors, $_[0];
    1;
});

is_deeply(\@items_selectable, ['  quarterstaff       [Basic]']);

is_deeply([splice @selectors], ['a'], "our four selectors were passed in as arguments");

is($menu->commit, '^a', "select the first thing on the first page, which exits the menu");

