use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::Exception;
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

my $menu = NetHack::Menu->new(vt => $vt);

is(@rows_checked, 0, "No rows checked yet.");

push @rows_returned, split /\n/, (<< 'MENU') x 2;
                     Weapons
                     a - a blessed +1 quarterstaff (weapon in hands)
                     Armor
                     X + an uncursed +0 cloak of magic resistance (being worn)
                     (end) 
MENU

ok($menu->at_end, "it knows we're at the end here");
checked_ok([0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4], "rows 0-5 checked for finding the end, 0-4 checked for items");

dies_ok { $menu->next } "next dies if menu->at_end";
checked_ok([], "no rows checked");

my @select_items;
$menu->select(sub {
    push @select_items, shift;
    /quarterstaff/;
});

my @deselect_items;
$menu->deselect(sub {
    push @deselect_items, shift;
    1;
});

cmp_deeply(
    \@select_items,
    [
        methods(
            description         => "a blessed +1 quarterstaff (weapon in hands)",
            selector            => 'a',
            selected            => 0,
            quantity            => 0,
            originally_selected => 0,
            original_quantity   => 0,
        ),
        methods(
            description         => "an uncursed +0 cloak of magic resistance (being worn)",
            selector            => 'X',
            selected            => 0,
            quantity            => 0,
            originally_selected => 1,
            original_quantity   => 'all',
        ),
    ],
);

is($menu->commit, '^X ', "first page, deselected the cloak, ended the menu");

done_testing;

