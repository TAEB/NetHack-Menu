package MockVT;
use strict;
use warnings;
use parent 'Term::VT102';
use NetHack::Menu;

my @return_rows;
my @checked_rows;

sub checked_rows {
    my $self = shift;
    return @checked_rows;
}

sub return_rows {
    my $self = shift;
    push @return_rows, @_;
}

sub next_return_row { shift @return_rows }

sub rows { 24 }

sub row_plaintext {
    my $self = shift;
    push @checked_rows, shift;
    return '' if $checked_rows[-1] == 0;
    $self->next_return_row;
}

sub checked_ok {
    my $self = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::is_deeply([splice @checked_rows], @_);
}

1;

