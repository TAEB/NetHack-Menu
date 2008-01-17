#!perl -T
use strict;
use warnings;
use Test::More tests => 6;
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

my $menu = NetHack::Menu->new(vt => $vt, select_count => 'none');

is(@rows_checked, 0, "No rows checked yet.");

push @rows_returned, split /\n/, (<< 'MENU');
                                            Discoveries
                                            
 -----------       --------                 Potions
 |+........-#######|......|                   potion of sickness (effervescent)
 |....(..?.|      #|..$....######           Tools
 |........)-    ###|@..<..|     # -----     * sack (bag)
 ------|----     ##.......-##   ##.$))|#### --More--
       ###       ##|......| #     |%...#   #     #           #    |.......|
         #     ####-------- ###   |...|#   #     #           #####|........#
MENU

ok($menu->has_menu, "we has a menu");
checked_ok([0, 1, 2, 3, 4, 5, 6, 7], "rows 0-7 checked for finding the end");

is($menu->next, ' ', "next page");

my @items_selectable;
$menu->select(sub {
    push @items_selectable, $_;
});

is_deeply(\@items_selectable, [
    "Discoveries",
    "",
    "Potions",
    "  potion of sickness (effervescent)",
    "Tools",
    "* sack (bag)",
]);

is($menu->commit, '', "select nothing, even though we want to");

