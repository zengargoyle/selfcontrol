#!perl

use Test::More tests => 2;

#diag( "Testing SelfControl $SelfControl::VERSION, Perl $], $^X" );

# Needed system programs in PATH, match '/bin/*' for better matching.
like( qx/which iptables/, qr:bin/iptables:, "Have 'iptables'");
like( qx/which at/, qr:bin/at:, "Have 'at'");
