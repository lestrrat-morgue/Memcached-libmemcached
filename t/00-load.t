#!perl -T

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
	use_ok( 'Memcached::libmemcached' );
}

my $VERSION = $Memcached::libmemcached::VERSION;
ok $VERSION, '$Memcached::libmemcached::VERSION should be defined';

diag( "Testing Memcached::libmemcached $VERSION, Perl $], $^O, $^X" );

ok defined &Memcached::libmemcached::memcached_lib_version,
    '&Memcached::libmemcached::memcached_lib_version should be defined';

my $lib_version = Memcached::libmemcached::memcached_lib_version();
ok $lib_version;

like $VERSION, qr/^\Q$lib_version\E\d\d/,
    "$VERSION should be $lib_version with two digits appended",
