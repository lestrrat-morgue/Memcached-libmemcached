
# tests for functions documented in memcached_stats.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
    ),
    #   other functions used by the tests
    qw(
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

plan tests => 5;

ok $memc;

# walk_stats()

{
    # statistics information actually change from version to version,
    # so we can't even be sure of the number of tests.
    # We could probably do a version specific testing, but for now
    # just check that the some constant items/constraints stay constant.
    my $arg_count_ok = 1;
    my $keys_defined_ok = 1;
    my $hostport_defined_ok = 1;
    my $type_ok = 1;
    $memc->walk_stats("misc", sub {
        # my ($key, $value, $hostport, $type) = @_;
        $arg_count_ok = scalar(@_) == 4 if $arg_count_ok;
        $keys_defined_ok = defined $_[0] if $keys_defined_ok;
        $hostport_defined_ok = defined $_[2] if $hostport_defined_ok;
        $type_ok = defined $_[3] && "misc" eq $_[3] if $type_ok;
    });
    ok( $arg_count_ok, "walk_stats argument count is sane" );
    ok( $keys_defined_ok, "keys are sane" );
    ok( $hostport_defined_ok, "hostport are sane" );
    ok( $type_ok, "types are sane" );
}
