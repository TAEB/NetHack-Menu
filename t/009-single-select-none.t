use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::Fatal;
use Test::Deep;

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
                     Weapons
                     a - a blessed +1 quarterstaff (weapon in hands)
                     Armor
                     X - an uncursed +0 cloak of magic resistance (being worn)
                     (1 of 2) 
MENU

ok($menu->has_menu, "we has a menu");
checked_ok([0, 1, 2, 3, 4, 5], "rows 0-5 checked for finding the end");

ok(!$menu->at_end, "it knows we're NOT at the end");
checked_ok([0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4], "rows 0-5 checked for finding the end, 0-4 checked for items");
is($menu->next, '>', "next page");
like(shift(@rows_returned), qr/^\s*\(1 of 2\)\s*$/, "last row to be returned is our 'end of menu indicator");
is(@rows_returned, 0, "no more rows left");

push @rows_returned, split /\n/, (<< 'MENU') x 2;
                     Wands
                     c - a wand of enlightenment (0:12)
                     Tools
                     n - a magic marker (0:91)
                     (2 of 2) 
MENU

ok($menu->at_end, "NOW we're at the end");
checked_ok([0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4], "rows 0-5 checked for finding the end, 0-4 checked for items");
ok(exception { $menu->next }, "next dies if menu->at_end");

my @items;
$menu->select(sub {
    push @items, shift;
    0;
});

cmp_deeply(
    \@items,
    [
        methods(
            description          => "a blessed +1 quarterstaff (weapon in hands)",
            selector             => 'a',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
        methods(
            description          => "an uncursed +0 cloak of magic resistance (being worn)",
            selector             => 'X',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
        methods(
            description          => "a wand of enlightenment (0:12)",
            selector             => 'c',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
        methods(
            description          => "a magic marker (0:91)",
            selector             => 'n',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
    ],
);

is($menu->commit, '^> ', "select nothing, even though we want to");

done_testing;
