
# tests for functions documented in memcached_get.pod
# (except for memcached_fetch_result)

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_mget
        memcached_fetch
    ),
    #   other functions used by the tests
    qw(
        memcached_set
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

plan tests => 3;

my ($rv, $rc, $flags);
my $t1= time();

my %data = map { ("k$_.$t1" => "v$_.$t1") } (1..3);

is memcached_set($memc, $_, $data{$_}), 'SUCCESS'
    for keys %data;

exit 0;

# XXX the number_of_keys argument can be removed in a later version
# I've left it here to (slightly) simplify the initial work
is memcached_mget($memc, [ keys %data ], scalar keys %data), 'SUCCESS';

my %got;
my $key;
while (defined( my $value = memcached_fetch($memc, $key, $flags, $rc) )) {
    $got{ $key } = $value;
}

is_deeply \%got, \%data;

