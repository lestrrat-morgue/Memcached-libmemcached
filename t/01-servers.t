
use Test::More tests => 6;

BEGIN {
use_ok( 'Memcached::libmemcached' );
}

my $server_list;
$server_list = Memcached::libmemcached::servers->servers_parse("foo:42");
ok $server_list, 'should return true';
ok ref $server_list, 'should return a ref';

is $server_list->server_list_count, 1, 'should have 1 element';

$server_list->server_list_free;


$server_list = Memcached::libmemcached::servers->servers_parse("foo:42, localhost, bar");

is $server_list->server_list_count, 3, 'should have 3 elements';

$server_list->server_list_free;

ok 1;
