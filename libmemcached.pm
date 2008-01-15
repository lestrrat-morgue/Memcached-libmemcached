package Memcached::libmemcached;

use warnings;
use strict;

=head1 NAME

Memcached::libmemcached - Thin fast interface to the libmemcached client API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.1301';

use Carp;
use base qw(Exporter);

use Memcached::libmemcached::API;
our @EXPORT_OK = (
    libmemcached_functions(),
    libmemcached_constants(),
);
our %EXPORT_TAGS = libmemcached_tags();

require XSLoader;
XSLoader::load('Memcached::libmemcached', $VERSION);

=head1 SYNOPSIS

  use Memcached::libmemcached;


=head1 EXPORTS

All the public functions in libmemcached are available for import.

All the public constants and enums in libmemcached are available for import.

Exporter tags are defined for each enum. This allows you to import groups of
constants easily. For example, to import all the contants for
memcached_behavior_set() and memcached_behavior_get(), you can use:

  use Memcached::libmemcached qw(:memcached_behavior).

=head1 FUNCTIONS

=head2 Conventions

Memcached::libmemcached is a very thin, highly efficient, wrapper around the
libmemcached library.  The libmemcached library documentation (which is bundled
with Memcached::libmemcached) serves as the primary reference for the functionality.

This documentation aims to provide just a summary of the functions, along with
any issues specific to this perl interface.

=head3 Terminology

The term "memcache" is used to refer to the C<memcached_st> structure at the
heart of the libmemcached library. The examples use $memc to represent this
structure.

=head3 Arguments

There are no I<length> arguments. Wherever the libmemcached documentation shows
a length argument (input or output) the corresponding argument doesn't exist in
the Perl API.

For pointer arguments, undef is mapped to null on input and null is mapped to
undef on output.

=head2 Return

Most of the methods return an integer status value. This is shown as
memcached_return in the libmemcached documentation. 

TODO: make a dual-var with integer and string parts (via typemap)

=cut


=head2 Functions For Managing Server Lists

=head3 XXX


=cut


=head2 Functions For Managing Memcaches

=head3 memcached_create

  my $memc = memcached_create();

Creates and returns a 'memcache' that represents the state of
communication with a set of memcached servers.
See L<Memcached::libmemcached::memcached_create>.

=head3 memcached_clone

  my $memc = memcached_clone(undef, undef);

XXX Not currently recommended for use.
See L<Memcached::libmemcached::memcached_create>.

=head3 memcached_free

  memcached_free($memc);

Frees the memory associated with $memc.
Your application will leak memory unless you call this.
After calling it $memc must not be used.
See L<Memcached::libmemcached::memcached_create>.

=head3 memcached_server_push

  memcached_server_push($memc, $server_list_object);

Adds a list of servers to the libmemcached object.
See L<Memcached::libmemcached::memcached_servers>.

=head3 memcached_server_count

  $server_count= memcached_server_count($memc);

Returns a count of the number of servers
associated with $memc.
See L<Memcached::libmemcached::memcached_servers>.

=head3 memcached_server_list

  $server_list= memcached_server_list($memc);

Returns the server list structure associated with $memc.
XXX Not currently recommended for use.
See L<Memcached::libmemcached::memcached_servers>.

=head3 memcached_server_add

  memcached_server_add($memc, $hostname, $port);

Adds details of a single memcached server (accessed via TCP/IP) to $memc.
See L<Memcached::libmemcached::memcached_servers>.

=head3 memcached_server_add_unix_socket

  memcached_server_add_unix_socket($memc, $socket_path);

Adds details of a single memcached server (accessed via a UNIX domain socket) to $memc.
See L<Memcached::libmemcached::memcached_servers>.

=head3 memcached_behavior_set

  memcached_behavior_set($memc, $option_key, $option_value);

Changes the value of a particular option.
See L<Memcached::libmemcached::memcached_behavior>.

=head3 memcached_behavior_get

  memcached_behavior_get($memc, $option_key);

Get the value of a particular option.
See L<Memcached::libmemcached::memcached_behavior>.

=head3 memcached_verbosity

  memcached_verbosity($memc, $verbosity)

Modifies the "verbosity" of the associated memcached servers.
See L<Memcached::libmemcached::memcached_verbosity>.

=head3 memcached_flush

  memcached_flush($memc, $expiration);

Wipe clean the contents of associated memcached servers.
See L<Memcached::libmemcached::memcached_flush>.

=head3 memcached_quit

  memcached_quit($memc);

Disconnect from all currently connected servers and reset state.
Not normally called explicitly.
See L<Memcached::libmemcached::memcached_quit>.

=cut


=head2 Functions for Setting Values in memcached

=head3 memcached_set

  memcached_set($key, $value, $expiration, $flags)

Set a value "$value" keyed by "$key" in memcached. $expiration and 
$flags are optional, defaulted both to 0

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_set.pod

  memcached_append($key, $value, $expiration, $flags)

Append a value "$value" keyed by "$key" in memcached to existing value
$key refers to. $expiration and $flags are optional, defaulted both to 0

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_set.pod

  memcached_prepend($key, $value, $expiration, $flags)

Pre-pend a value "$value" keyed by "$key" in memcached to existing value
$key refers to. $expiration and $flags are optional, defaulted both to 0

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_set.pod

=cut


=head2 Functions for Incrementing and Decrementing Values from memcached

=head3 memcached_increment

  $return = memcached_increment( $key, $offset, $new_value_out );

Increments the value associated with $key by $offset and returns the new value in $new_value_out.
See also L<Memcached::libmemcached::memcached_auto>.

=head3 memcached_decrement 

  memcached_decrement( $key, $offset, $new_value_out );

Decrements the value associated with $key by $offset and returns the new value in $new_value_out.
See also L<Memcached::libmemcached::memcached_auto>.

=cut


=head2 Functions for Fetching Values from memcached

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_get.pod

=cut


=head2 Functions for Managing Results from memcached

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_result_st.pod

=cut


=head2 Functions for Deleting Values from memcached

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_delete.pod

=cut


=head2 Functions for Accessing Statistics from memcached

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_stats.pod

=cut


=head2 Miscellaneous Functions

=head3 memcached_strerror

  $string = memcached_strerror($memc, $return_code)

memcached_strerror() takes a C<memcached_return> value and returns a string describing the error.
The string should be treated as read-only (it may be so in future versions).
See also L<Memcached::libmemcached::memcached_strerror>.

=cut





=head1 AUTHOR

Tim Bunce, C<< <Tim.Bunce@pobox.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-memcached-libmemcached@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Memcached-libmemcached>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Tim Bunce, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Memcached::libmemcached
