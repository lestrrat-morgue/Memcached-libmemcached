
use Test::More tests => 6;

BEGIN {
use_ok( 'Memcached::libmemcached' );
}

my $server_list = Memcached::libmemcached::servers->servers_parse("localhost:1234");
ok ref $server_list, 'should return a ref';

my $memc = Memcached::libmemcached->create();
ok $memc, 'should return a true value';
ok ref $memc, 'should return a ref';

$memc->server_push($server_list);

my $ret_server_list= $memc->server_list();
ok $ret_server_list, 'should return a list';
ok ref $ret_server_list, 'should return a ref';

# $memc->free(); # causes code dump
