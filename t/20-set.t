# tests for functions documented in memcached_XXX.pod

use Test::More tests => 2;

BEGIN {
use_ok( 'Memcached::libmemcached',
#   functions explicitly tested by this file
qw(
   memcached_set
),
#   other functions used by the tests
qw(
    memcached_server_add
    memcached_create
    memcached_free
));
}

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();
ok $memc;

ok memcached_set($memc, 'abc', "this is a test");
