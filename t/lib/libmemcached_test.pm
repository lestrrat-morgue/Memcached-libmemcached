package libmemcached_test;

# functions to support the Memcached::libmemcached test suite

use strict;
use warnings;
use base 'Exporter';

our @EXPORT = qw(
    libmemcached_test_create
);

use Memcached::libmemcached qw(
    memcached_create
    memcached_server_add
);

sub libmemcached_test_create {

    my $memc = memcached_create();

    my $opts = $ENV{PERL_LIBMEMCACHED_OPTS} || 'localhost';

    # XXX may change to memcached_parse_options or somesuch so the env
    # var can set behaviours etc
    my $rc = memcached_server_add($memc, $opts);
    die "libmemcached_test_create: memcached_server_add($opts) failed: $rc" if $rc != 0;

    return $memc;
}


1;
