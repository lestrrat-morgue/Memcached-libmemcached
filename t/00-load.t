#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'Memcached::libmemcached' );
}

diag( "Testing Memcached::libmemcached $Memcached::libmemcached::VERSION, Perl $], $^O, $^X" );
