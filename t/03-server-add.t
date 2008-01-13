# tests for functions documented in memcached_create.pod
# XXX memcached_clone needs more testing for non-undef args

use Test::More tests => 4;

BEGIN {
use_ok( 'Memcached::libmemcached', qw(
    memcached_create
    memcached_free
    memcache_server_add
),
#   other functions used by the tests
qw(
));
}

my ($memc, $retval);

ok $memc = memcached_create();

ok $retval = memcached_server_add('localhost');

memcached_free($memc);

ok 1;
