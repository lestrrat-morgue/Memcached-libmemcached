package libmemcached_test;

# functions to support the Memcached::libmemcached test suite

use strict;
use warnings;
use base 'Exporter';

use Test::More;

our @EXPORT = qw(
    libmemcached_test_create
    libmemcached_test_key
);

use Memcached::libmemcached qw(
    memcached_create
    memcached_server_add
    memcached_get
    memcached_errstr
    memcached_version
);

sub libmemcached_test_create {
    my ($args) = @_;

    my $memc = memcached_create()
        or die "memcached_create failed";

    my $opts = $ENV{PERL_LIBMEMCACHED_OPTS} || 'localhost';

    # XXX may change to memcached_parse_options or somesuch so the env
    # var can set behaviours etc
    my $rc = memcached_server_add($memc, $opts);
    die "libmemcached_test_create: memcached_server_add($opts) failed: ".memcached_errstr($memc)
        if not $rc;

    # XXX ideally this should be a much 'simpler/safer' command
    memcached_get($memc, "foo");
    plan skip_all => "Can't talk to any memcached servers"
        if memcached_errstr($memc) !~ /SUCCESS|NOT FOUND/;

    plan skip_all => "memcached server version less than $args->{min_version}"
        if $args->{min_version}
        && not libmemcached_version_ge($memc, $args->{min_version});

    return $memc;
}


sub libmemcached_version_ge {
    my ($memc, $min_version) = @_;
    my @min_version = split /\./, $min_version;

    my @memcached_version = memcached_version($memc);

    for (0,1,2) {
        return 1 if $memcached_version[$_] > $min_version[$_];
        return 0 if $memcached_version[$_] < $min_version[$_];
    }
    return 1; # identical versions
}


sub libmemcached_test_key {
    # return a value suitable for use as a memcached key
    # that is unique for each run of the script
    # but returns the same value for the life of the script
    our $time_rand ||= ($^T + rand());
    return $time_rand;
}

1;
