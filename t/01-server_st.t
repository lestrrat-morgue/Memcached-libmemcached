# tests for functions documented in memcached_server_st.pod

use Test::More tests => 5;

BEGIN {
use_ok( 'Memcached::libmemcached', qw(
    memcached_servers_parse
    memcached_server_list_count
    memcached_server_list_free
));
}

my $server_list;

$server_list = memcached_servers_parse("foo:42");
ok $server_list, 'should return true';

is memcached_server_list_count($server_list), 1, 'should have 1 element';

memcached_server_list_free($server_list);


$server_list = memcached_servers_parse("foo:42, localhost, bar");

is memcached_server_list_count($server_list), 3, 'should have 3 elements';

memcached_server_list_free($server_list);


# memcached_server_list_append is deprecated

ok 1;
