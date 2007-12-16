#!perl -T
use strict;
use warnings;
use Test::More tests => 22;
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

push @rows_returned, split /\n/, (<< 'MENU') x 2;
                     a - page 1
                     (3 of 4) 
MENU

ok(!$menu->at_end, "it knows we're NOT at the end");
checked_ok([0, 1, 2, 0, 1], "rows 0-2 checked for finding the end, 0-1 checked for items");
is($menu->next, '>', "next page");
like(shift(@rows_returned), qr/^\s*\(3 of 4\)\s*$/, "last row to be returned is our 'end of menu indicator");
is(@rows_returned, 0, "no more rows left");

push @rows_returned, split /\n/, (<< 'MENU') x 2;
                     b - page 2
                     (4 of 4) 
MENU

ok(!$menu->at_end, "it knows we're NOT at the end");
checked_ok([0, 1, 2, 0, 1], "rows 0-2 checked for finding the end, 0-1 checked for items");
is($menu->next, '^', "back to first page");
like(shift(@rows_returned), qr/^\s*\(4 of 4\)\s*$/, "last row to be returned is our 'end of menu indicator");
is(@rows_returned, 0, "no more rows left");

push @rows_returned, split /\n/, (<< 'MENU') x 2;
                     c - page 3
                     (1 of 4) 
MENU

ok(!$menu->at_end, "it knows we're NOT at the end");
checked_ok([0, 1, 2, 0, 1], "rows 0-2 checked for finding the end, 0-1 checked for items");
is($menu->next, '>', "back to first page");
like(shift(@rows_returned), qr/^\s*\(1 of 4\)\s*$/, "last row to be returned is our 'end of menu indicator");
is(@rows_returned, 0, "no more rows left");

push @rows_returned, split /\n/, (<< 'MENU') x 2;
                     d - page 4
                     (2 of 4) 
MENU

ok($menu->at_end, "NOW we're at the end");
checked_ok([0, 1, 2, 0, 1], "rows 0-2 checked for finding the end, 0-1 checked for items");
dies_ok { $menu->next } "next after end dies";

my @items_selectable;
my @selectors;
$menu->select(sub {
    push @items_selectable, $_;
    push @selectors, $_[0];
    /[23]/;
});

is_deeply(\@items_selectable, ["page 3", "page 4", "page 1", "page 2"], "items are returned in page order, not compiled order");

is_deeply(\@selectors, ['c', 'd', 'a', 'b'], "our four selectors were passed in as arguments");

is($menu->commit, '^c>>>b ', "first page, select 1, fourth page, select 4, done");

