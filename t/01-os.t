#!perl

use Test::More;

my %cmd = (
  iptables => 1,
  at => 1,
  ed => 1,
);

plan tests => scalar keys %cmd;

#diag( "Testing SelfControl $SelfControl::VERSION, Perl $], $^X" );

for my $cmd (keys %cmd) {
  ok(length `which $cmd`, "Have '$cmd' in \$PATH");
}
