#!perl -T
use strict;
use warnings;
use Test::More tests => 3;
use Test::MockObject;
use Test::Exception;

use NetHack::Menu;

my @rows_returned;
sub row_plaintext {
    my $self = shift;
    shift @rows_returned;
}

my $vt = Test::MockObject->new;
$vt->mock(row_plaintext => \&row_plaintext);
$vt->set_always(rows => 24);
$vt->set_isa('Term::VT102');

my $menu = NetHack::Menu->new(vt => $vt);

push @rows_returned, split /\n/, (<< 'MENU') x 3;
                     Weapons
                     a - 1A
                     b + 1B
                     c # 1C
                     d - 2A
                     e + 2B
                     f # 2C
                     g - 3A
                     h + 3B
                     i # 3C
                     j - 4A
                     k + 4B
                     l # 4C
                     (end) 
MENU

ok($menu->has_menu, "we has a menu");

ok($menu->at_end, "it knows we're at the end here");

$menu->select_quantity(sub {
    /1[ABC]/ ? undef : /2[ABC]/ ? 0 : /3[ABC]/ ? 5 : 'all';
});

is($menu->commit, '^ef5g5h5ijll ', "menu commit handles all combinations");
