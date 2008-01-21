
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
        memcached_mget_into_hashref
    ),
    #   other functions used by the tests
    qw(
        memcached_set
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

my $items = 5;
plan tests => $items + 3
    + 2 * (1 + $items * 2 + 1)
    + $items + 2;

my ($rv, $rc, $flags);
my $t1= time();

my %data = map { ("k$_.$t1" => "v$_.$t1") } (1..$items-2);
# add extra long and extra short items to help spot buffer issues
$data{"kL.LLLLLLLLLLLLLLLLLL"} = "vLLLLLLLLLLLLLLLLLLLL";
$data{"kS.S"} = "vS";

is memcached_set($memc, $_, $data{$_}), 'SUCCESS'
    for keys %data;

isnt memcached_mget($memc, undef), 'SUCCESS';
isnt memcached_mget($memc, 0),     'SUCCESS';
isnt memcached_mget($memc, 1),     'SUCCESS';

for my $keys_ref (
    [ keys %data ],
    { % data },
) {
    is memcached_mget($memc, $keys_ref), 'SUCCESS';

    my %got;
    my $key;
    while (defined( my $value = memcached_fetch($memc, $key, $flags, $rc) )) {
        is $rc, 'SUCCESS';
        is $flags, 0;
        print "memcached_fetch($key) => $value\n";
        $got{ $key } = $value;
    }

    is_deeply \%got, \%data;
}


print "memcached_mget_into_hashref\n";

# tweak data so it's different from previous tests
%data = map { $_ . "a" } %data;
#use Data::Dumper; warn Dumper(\%data);

is memcached_set($memc, $_, $data{$_}), 'SUCCESS'
    for keys %data;

my %extra = ( foo => 'bar' );
# reset got data, but not to empty so we check the hash isn't erased
my %got = %extra;
is memcached_mget_into_hashref($memc, [ keys %data ], \%got), 'SERVER END';

is_deeply \%got, { %data, %extra };

