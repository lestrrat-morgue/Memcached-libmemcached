
# tests for functions documented in memcached_strerror.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_strerror
        memcached_errstr
    ),
    #   other functions used by the tests
    qw(
        memcached_server_add_unix_socket
        MEMCACHED_FAILURE
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

plan tests => 5;

is memcached_strerror($memc, 0), 'SUCCESS';
is memcached_strerror($memc, 1), 'FAILURE';

# XXX also test dual-var nature of return codes here
my $rc = memcached_server_add_unix_socket($memc, undef); # should fail
ok !defined($rc), 'rc should not be defined';

my $errstr = memcached_errstr($memc);
#use Devel::Peek; Dump($errstr);
cmp_ok $errstr, '==', MEMCACHED_FAILURE(),
    'should be MEMCACHED_FAILURE integer in numeric context';
cmp_ok $errstr, 'eq', "FAILURE",
    'should be "FAILURE" string in string context';
