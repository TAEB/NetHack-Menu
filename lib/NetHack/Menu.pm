#!perl
package NetHack::Menu;
use Moose;

has vt => (
    is       => 'rw',
    isa      => 'Term::VT102',
    required => 1,
    handles  => ['row_plaintext', 'rows'],
);

has page_number => (
    is      => 'rw',
    isa     => 'Int',
);

has page_count => (
    is      => 'rw',
    isa     => 'Int',
);

has pages => (
    is      => 'rw',
    isa     => 'ArrayRef[ArrayRef]',
    default => sub { [] },
);

sub at_end {
    my $self = shift;

    for (0 .. $self->rows) {
        if ($self->row_plaintext($_) =~ /^(.*)\((end|(\d+) of (\d+))\)\s*$/) {
            my ($current, $max) = ($3, $4);
            ($current, $max) = (1, 1) if ($2||'') eq 'end';

            # this may happen if someone is trying to screw with us and gives
            # us a page number or page count of 0
            next unless $current && $max;

            $self->page_number($current);
            $self->page_count($max);
            $self->parse_current_page(length($1), $_);
            last;
        }
    }

    defined($self->page_number)
        or Carp::croak "Unable to parse a menu.";

    for (1 .. $self->page_count) {
        if (@{ $self->pages->[$_] || [] } == 0) {
            return 0;
        }
    }

    return 1;
}

sub parse_current_page {
    my $self      = shift;
    my $start_col = shift;
    my $end_row   = shift;

    # have we already parsed this one?
    my $page = $self->pages->[ $self->page_number ] ||= [];
    return if @$page;

    my $re = qr/^(?:.{$start_col})(.) ([-+]) (.*?)\s*$/;
    for (0 .. $end_row - 1) {
        next unless $self->row_plaintext($_) =~ $re;
        my ($selector, $selected, $name) = ($1, $2 eq '+', $3);

        push @$page, [
            $name,
            $selector,
            $selected,
            $selected,
        ];
    }

    confess "Unable to parse the current menu page." if !@$page;
}

sub next {
    my $self = shift;

    # look for the first page after the current page that hasn't been parsed
    for ($self->page_number + 1 .. $self->page_count) {
        if (@{ $self->pages->[$_] || [] } == 0) {
            return join '', map {'>'} $self->page_number + 1 .. $_;
        }
    }

    # now look for any pages we may have missed at the beginning
    for (1 .. $self->page_number - 1) {
        if (@{ $self->pages->[$_] || [] } == 0) {
            return '^' . join '', map {'>'} $self->page_number + 1 .. $_;
        }
    }

    # we're done, but the user isn't following our API
    confess "$self->next called even though $self->at_end is true.";
}

sub select {
    my $self = shift;
    my $code = shift;

    for (map { @{ $_ || [] } } @{ $self->pages }) {
        my ($name, $selector, $selected, $started_selected) = @$_;

        my $select = do {
            local $_ = $name;
            $code->($selector);
        };

        if ($select && !$selected) {
            $_->[2] = 1;
        }
    }
}

sub deselect {
    my $self = shift;
    my $code = shift;

    for (map { @{ $_ || [] } } @{ $self->pages }) {
        my ($name, $selector, $selected, $started_selected) = @$_;

        my $deselect = do {
            local $_ = $name;
            $code->($selector);
        };

        if ($deselect && $selected) {
            $_->[2] = 0;
        }
    }
}

sub commit {
    my $self = shift;

    my @pages = map {
        join '', map {
            $_->[2] != $_->[3] ? $_->[1] : '';
        } @{ $_ || [] }
    } @{ $self->pages };

    shift @pages; # there is no page 0

    return '^' . join('>', @pages) . ' ';
}

=head1 NAME

NetHack::Menu - interact with NetHack's menus

=head1 VERSION

Version 0.01 released ???

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use NetHack::Menu;
    my $menu = NetHack::Menu->new(vt => $term_vt102);

    # compile all pages of the menu
    until ($menu->at_end) {
        $term_vt102->process($nh->send_and_recv($menu->next));
    }

    $menu->select(sub { /blessed/ });
    $menu->deselect(sub { /cancell|bag.*(holding|tricks)/ });

    $term_vt102->process($nh->send_and_recv($menu->end));

=head1 DESCRIPTION

NetHack requires a lot of menu management. This module aims to alleviate the
difficulty of parsing and interacting with menus.

=head1 SEE ALSO

L<Foo::Bar>

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail.com> >>

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-nethack-menu at rt.cpan.org>, or browse
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=NetHack-Menu>.

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc NetHack::Menu

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/NetHack-Menu>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/NetHack-Menu>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=NetHack-Menu>

=item * Search CPAN

L<http://search.cpan.org/dist/NetHack-Menu>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

