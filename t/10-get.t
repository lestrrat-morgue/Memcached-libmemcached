# tests for functions documented in memcached_XXX.pod

use Test::More tests => 4;

BEGIN {
use_ok( 'Memcached::libmemcached',
#   functions explicitly tested by this file
qw(
  memc_get
  memc_set
),
#   other functions used by the tests
qw(
));
}

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();
ok $memc;

my $test_data= "test data";
ok memcached_set($memc, "abc", $test_data);

my $ret_data=
ok $ret_data= memcached_get($memc, "abc");

is( $ret_data, $test_data, 'Should both be equal' );
