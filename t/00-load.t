#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'SelfControl' ) || print "Bail out!
";
    use_ok( 'SelfControl::Config' ) || print "Bail out!
";
    use_ok( 'SelfControl::UI' ) || print "Bail out!
";
    use_ok( 'SelfControl::Root' ) || print "Bail out!
";
}

diag( "Testing SelfControl $SelfControl::VERSION, Perl $], $^X" );
