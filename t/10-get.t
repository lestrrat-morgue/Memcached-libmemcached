# tests for functions documented in memcached_XXX.pod

use Test::More tests => 5;

BEGIN {
use_ok( 'Memcached::libmemcached',
#   functions explicitly tested by this file
qw(
  memcached_get
),
#   other functions used by the tests
qw(
  memcached_set
));
}

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();
ok $memc;

my $test_data= "test data ".time();
ok memcached_set($memc, "abc", $test_data);

my $ret_data;
ok $ret_data= memcached_get($memc, "abc", my $len=0, 0, my $rc=0);

is( $ret_data, $test_data, 'Should both be equal' );
