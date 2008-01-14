# tests for functions documented in memcached_behavior.pod

use Test::More tests => 8;

#$Exporter::Verbose = 1;

BEGIN {
use_ok( 'Memcached::libmemcached',
#   functions explicitly tested by this file
qw(
    memcached_behavior_get
    memcached_behavior_set
),
#   other functions and constants used by the tests
qw(
    MEMCACHED_BEHAVIOR_TCP_NODELAY
));
}
use Memcached::libmemcached qw(MEMCACHED_BEHAVIOR_TCP_NODELAY);

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();
ok $memc;

my $rv = memcached_behavior_get($memc, MEMCACHED_BEHAVIOR_TCP_NODELAY);
ok defined $rv;
ok !$rv;

ok memcached_behavior_set($memc, MEMCACHED_BEHAVIOR_TCP_NODELAY, 1);

ok memcached_behavior_get($memc, MEMCACHED_BEHAVIOR_TCP_NODELAY);

ok memcached_behavior_set($memc, MEMCACHED_BEHAVIOR_TCP_NODELAY, 0);

ok !memcached_behavior_get($memc, MEMCACHED_BEHAVIOR_TCP_NODELAY);
