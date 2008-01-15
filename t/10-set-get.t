
# tests for basic memcached_set & memcached_get
# documented in memcached_set.pod and memcached_get.pod
# test for the other functions are performed elsewhere

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
    memcached_set
    memcached_get
    ),
    #   other functions used by the tests
    qw(
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

plan tests => 6;

my ($rv, $rc, $flags);
my $t1= time();
my $k1= "$0-test-key-$t1"; # can't have spaces
my $v1= "$0 test value $t1";

# get (presumably non-existant) key
print "memcached_get the not yet stored value\n";
is scalar memcached_get($memc, $k1, $flags=0, $rc=0), undef,
    'should not exist yet and so should return undef';

print "memcached_set\n";
is memcached_set($memc, $k1, $v1), "SUCCESS";

print "memcached_get the just stored value\n";
is memcached_get($memc, $k1, $flags=0, $rc=0), $v1;
cmp_ok $rc, 'eq', 'SUCCESS';
is $flags, 0;

# repeat for value with a null byte to check value_length works
