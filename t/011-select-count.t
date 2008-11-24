#!perl -T
use strict;
use warnings;
use Test::More tests => 10;
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

my $menu = NetHack::Menu->new(vt => $vt);

is(@rows_checked, 0, "No rows checked yet.");

push @rows_returned, split /\n/, (<< 'MENU') x 3;
                     Weapons
                     a - a blessed +1 quarterstaff (weapon in hands)
                     d - 14 uncursed +3 daggers
                     X - 3 cursed +0 darts
                     (end) 
MENU

ok($menu->has_menu, "we has a menu");
checked_ok([0, 1, 2, 3, 4, 5], "rows 0-5 checked for finding the end");

ok($menu->at_end, "it knows we're at the end here");
checked_ok([0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4], "rows 0-5 checked for finding the end, 0-4 checked for items");

dies_ok { $menu->next } "next dies if menu->at_end";
checked_ok([], "no rows checked");

my @items_selectable;
my @selectors;
$menu->select_quantity(sub {
    push @items_selectable, $_;
    push @selectors, $_[0];
    /quarterstaff/ ? 0 : /dagger/ ? 'all' : 2;
});

is_deeply(\@items_selectable, ["a blessed +1 quarterstaff (weapon in hands)", "14 uncursed +3 daggers", "3 cursed +0 darts"], "the items showed up");

is_deeply(\@selectors, ['a', 'd', 'X'], "our selectors were passed in as arguments");

is($menu->commit, '^d2X ', "first page, selected the daggers and 2 of the darts, ended the menu");
