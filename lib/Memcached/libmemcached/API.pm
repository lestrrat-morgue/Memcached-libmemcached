package Memcached::libmemcached::API;

=head1 NAME

Memcached::libmemcached::API - 

=head1 SYNOPSIS

    use Memcached::libmemcached::API;

    @names = libmemcached_functions();

=head1 DESCRIPTION

This module should be considered private. It may change or be removed in future.

=head1 FUNCTIONS

=cut

use base qw(Exporter);
our @EXPORT = qw(libmemcached_functions);

# load hash of libmemcached functions created by Makefile.PL
my $libmemcached_api = require "Memcached/libmemcached/api_hash.pl";
die "Memcached/libmemcached/api_hash.pl failed sanity check"
    unless ref $libmemcached_api eq 'HASH'
        and keys %$libmemcached_api > 20;

our @libmemcached_api = sort keys %$libmemcached_api;

=head2 libmemcached_functions

  @names = libmemcached_functions();

Returns a list of all the public functions in the libmemcached library.

=cut

sub libmemcached_functions { @libmemcached_api } 

1;
