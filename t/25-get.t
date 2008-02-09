
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

my $items = 5;
plan tests => $items + 3
    + 2 * (1 + $items * 2 + 1)
    + $items + 6;

my ($rv, $rc, $flags);
my $t1= time();

my %data = map { ("k$_.$t1" => "v$_.$t1") } (1..$items-2);
# add extra long and extra short items to help spot buffer issues
$data{"kL.LLLLLLLLLLLLLLLLLL"} = "vLLLLLLLLLLLLLLLLLLLL";
$data{"kS.S"} = "vS";

ok memcached_set($memc, $_, $data{$_})
    for keys %data;

ok !memcached_mget($memc, undef);
ok !memcached_mget($memc, 0);
ok !memcached_mget($memc, 1);

for my $keys_ref (
    [ keys %data ],
    { % data },
) {
    ok memcached_mget($memc, $keys_ref);

    my %got;
    my $key;
    while (defined( my $value = memcached_fetch($memc, $key, $flags, $rc) )) {
        ok $rc, 'rc should be true';
        is $flags, 0, 'flags should be 0';
        print "memcached_fetch($key) => $value\n";
        $got{ $key } = $value;
    }

    is_deeply \%got, \%data;
}

print "mget_into_hashref\n";

# tweak data so it's different from previous tests
%data = map { $_ . "a" } %data;
#use Data::Dumper; warn Dumper(\%data);

ok memcached_set($memc, $_, $data{$_})
    for keys %data;

ok $memc->mget_into_hashref([ ], {}),
    'should return true, even if no keys';

ok $memc->mget_into_hashref([ 'none such foo' ], {}),
    'should return true, even if no results';

my %extra = ( foo => 'bar' );
# reset got data, but not to empty so we check the hash isn't erased
my %got = %extra;
ok $memc->mget_into_hashref([ keys %data ], \%got),
    'should return true';

is_deeply \%got, { %data, %extra };

# refetch with duplicate keys, mainly to trigger realloc of key buffers
ok $memc->mget_into_hashref([ (keys %data) x 10 ], \%got),
    'should return true';

is_deeply \%got, { %data, %extra };

