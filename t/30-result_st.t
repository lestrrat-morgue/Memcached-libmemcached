
# tests for functions documented in memcached_result_st.pod

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
use_ok( 'Memcached::libmemcached',
#   functions explicitly tested by this file
qw(
),
#   other functions used by the tests
qw(
));
}

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();
ok $memc;
