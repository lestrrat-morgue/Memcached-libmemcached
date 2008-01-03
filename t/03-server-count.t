
use Test::More tests => 5;

BEGIN {
use_ok( 'Memcached::libmemcached' );
}

my $server_list = Memcached::libmemcached::servers->servers_parse("localhost:1234");
ok ref $server_list, 'should return a ref';

my $memc = Memcached::libmemcached->create();
ok $memc, 'should return a true value';
ok ref $memc, 'should return a ref';

is $memc->server_count, 0, 'should have 0 elements';

$memc->server_push($server_list);

is $memc->server_count, 1, 'should have 1 element';

# $memc->free(); # causes code dump
