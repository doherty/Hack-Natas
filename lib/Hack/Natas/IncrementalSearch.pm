package Hack::Natas::IncrementalSearch;
use strict;
use warnings;
use v5.16.0;
# VERSION
# ABSTRACT: do incremental searches for some Natas challenges

use Types::Standard qw(Int Str);
use Type::Utils qw(class_type);
use Moo::Role;
requires qw(
    password_length
    guess_next_char
    password
);

has password_so_far => (
    is      => 'rw',
    isa     => Str,
    default => sub { '' },
);

=head1 DESCRIPTION

This is a role for incrementally guessing the password in one-character
slices. It provides a C<password_so_far> attribute, which is used to
build up the full password. It requires that consumers have:

=over 4

=item * password_length

An integer which tells us how long the password is, so the search will stop
once we have the whole thing.

=item * guess_next_char

A method which, when called with the current position in the password, returns
the next character.

=back

=head1 METHODS

=head2 run

This is the only method you need to call. It will do the search, and once
C<password_length> characters of the password have been guessed using
C<guess_next_char>, the C<password> attribute will be set.

=cut

sub run {
    my $self = shift;

    foreach my $pos (1 .. $self->password_length) {
        $self->password_so_far( $self->password_so_far . $self->guess_next_char($pos) );
    }
    $self->password( $self->password_so_far );
}

1;
