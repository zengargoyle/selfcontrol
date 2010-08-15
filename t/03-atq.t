#!perl

use Test::More;

like(`((echo one;echo two;echo three;echo four)|sudo -S atq -V) 2>&1`,qr/at version/,"appear to have 'sudo atq' ability");

done_testing;
