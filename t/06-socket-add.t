
use Test::More tests => 7;

BEGIN {
use_ok( 'Memcached::libmemcached' );
}

my $server_list = Memcached::libmemcached::servers->servers_parse("localhost:1234");
ok ref $server_list, 'should return a ref';

my $memc = Memcached::libmemcached->create();
ok $memc, 'should return a true value';
ok ref $memc, 'should return a ref';

$memc->server_push($server_list);

is $memc->server_count, 1, 'should have 1 element';


$memc->server_add_unix_socket('/tmp/memc1.sock');
is $memc->server_count, 2, 'should have 2 elements';
$memc->server_add_unix_socket('/tmp/memc2.sock');
is $memc->server_count, 3, 'should have 3 elements';

# $memc->free(); # causes code dump
