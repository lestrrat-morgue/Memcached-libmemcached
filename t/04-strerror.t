
# tests for functions documented in memcached_strerror.pod

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
use_ok( 'Memcached::libmemcached',
#   functions explicitly tested by this file
qw(
    memcached_strerror
),
#   other functions used by the tests
qw(
    memcached_server_add_unix_socket
    MEMCACHED_FAILURE
));
}

use lib 't/lib';
use libmemcached_test;

my $rc;
my $memc = libmemcached_test_create();
ok $memc;

is memcached_strerror($memc, 0), 'SUCCESS';
is memcached_strerror($memc, 1), 'FAILURE';

# XXX also test dual-var nature of return codes here
$rc = memcached_server_add_unix_socket($memc, undef);
#use Devel::Peek; Dump($rc);
cmp_ok $rc, '==', MEMCACHED_FAILURE();
cmp_ok $rc, 'eq', "FAILURE";
