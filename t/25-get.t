
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

my $items = 3;
plan tests => ($items * 3) + 8;

my ($rv, $rc, $flags);
my $t1= time();

my %data = map { ("k$_.$t1" => "v$_.$t1") } (1..$items);
# add extra long and extra short items to help spot buffer issues
$data{"kL.LLLLLLLLLLLLLLLLLL"} = "vLLLLLLLLLLLLLLLLLLLL";
$data{"kS.S"} = "vS";

is memcached_set($memc, $_, $data{$_}), 'SUCCESS'
    for keys %data;

is memcached_mget($memc, [ keys %data ]), 'SUCCESS';

my %got;
my $key;
while (defined( my $value = memcached_fetch($memc, $key, $flags, $rc) )) {
    is $rc, 'SUCCESS';
    is $flags, 0;
    print "memcached_fetch($key) => $value\n";
    $got{ $key } = $value;
}

is_deeply \%got, \%data;

