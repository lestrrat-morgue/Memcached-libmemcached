
# tests for functions documented in memcached_strerror.pod

use Test::More tests => 4;

BEGIN {
use_ok( 'Memcached::libmemcached',
#   functions explicitly tested by this file
qw(
    memcached_strerror
),
#   other functions used by the tests
qw(
));
}

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();
ok $memc;

is memcached_strerror($memc, 0), 'SUCCESS';
is memcached_strerror($memc, 1), 'FAILURE';

# XXX also test dual-var nature of return codes here
