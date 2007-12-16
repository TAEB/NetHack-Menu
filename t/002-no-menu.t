#!perl -T
use strict;
use warnings;
use Test::More tests => 6;
use Test::MockObject;
use Test::Exception;

use NetHack::Menu;

my $vt = Test::MockObject->new;
$vt->set_always(rows => 24);
$vt->set_isa('Term::VT102');

my $menu = NetHack::Menu->new(vt => $vt);

$vt->set_always(row_plaintext => (' ' x 80));
throws_ok { $menu->at_end } qr/Unable to parse a menu/;

$vt->set_always(row_plaintext => '(end) or is it?');
throws_ok { $menu->at_end } qr/Unable to parse a menu/;

$vt->set_always(row_plaintext => '(1 of 1) but we make sure to check for \s*$');
throws_ok { $menu->at_end } qr/Unable to parse a menu/;

$vt->set_always(row_plaintext => '            (-1 of 1)   ');
throws_ok { $menu->at_end } qr/Unable to parse a menu/;

$vt->set_always(row_plaintext => '            (0 of 1)');
throws_ok { $menu->at_end } qr/Unable to parse a menu/;

$vt->set_always(row_plaintext => '            (1 of 0)');
throws_ok { $menu->at_end } qr/Unable to parse a menu/;

