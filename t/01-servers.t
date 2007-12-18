
use Test::More tests => 6;

BEGIN {
use_ok( 'Memcached::libmemcached' );
}

my $server_list;
$server_list = Memcached::libmemcached::servers->servers_parse("foo:42");
ok $server_list, 'should return true';
ok ref $server_list, 'should return a ref';

is $server_list->server_list_count, 1, 'should have 1 element';

$server_list = $server_list->server_list_append("bar", 43, my $error);

ok $server_list, 'should return true';
ok ref $server_list, 'should return a ref';

is $server_list->server_list_count, 2, 'should have 2 elements';
