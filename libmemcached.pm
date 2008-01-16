package Memcached::libmemcached;

use warnings;
use strict;

=head1 NAME

Memcached::libmemcached - Thin fast full interface to the libmemcached client API

=head1 VERSION

Version 0.1304

=cut

our $VERSION = '0.1304';

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

  $memc = memcached_create();
  memcached_server_add($memc, "localhost");

  memcached_set($memc, $key, $value);

  $value = memcached_get($memc, $key);

=head1 DESCRIPTION

Memcached::libmemcached is a very thin, highly efficient, wrapper around the
libmemcached library.

It gives full access to the rich functionality offered by libmemcached.
libmemcached is fast, light on memory usage, thread safe, and provide full
access to server side methods.

 - Synchronous and Asynchronous support.
 - TCP and Unix Socket protocols.
 - A half dozen or so different hash algorithms.
 - Implementations of the new cas, replace, and append operators.
 - Man pages written up on entire API.
 - Implements both modulo and consistent hashing solutions. 

(At the moment Memcached::libmemcached is very new and not all the functions in
libmemcached have perl interfaces yet. We're focussing on the core
infrastructure and the most common functions. It's usually trivial to add
functions - just a few lines in libmemcached.xs, a few lines of documentation,
and a few lines of testing.  Volunteers welcome!)

The libmemcached library documentation (which is bundled with this module)
serves as the primary reference for the functionality.

This documentation provides summary of the functions, along with any issues
specific to this perl interface, and references to the documentation for the
corresponding functions in the underlying library.

For more information on libmemcached, see L<http://tangent.org/552/libmemcached.html>

=head1 CONVENTIONS

=head2 Terminology

The term "memcache" is used to refer to the C<memcached_st> structure at the
heart of the libmemcached library. We'll use $memc to represent this
structure in perl code.

=head2 Function Arguments

There are no I<length> arguments. Wherever the libmemcached documentation shows
a length argument (input or output) the corresponding argument doesn't exist in
the Perl API, because it's not needed.

For pointer arguments, undef is mapped to null on input and null is mapped to
undef on output.

=head2 Return Status

Most of the methods return an integer status value. This is shown as
C<memcached_return> in the libmemcached documentation. 

In the perl interface this value is a I<dualvar>, like C<$!>, that has both
integer and string components set to different values.  In a numeric context
the value is the integer status code.  In a string content the value is the
corresponding error string.

All the functions documented below return a C<memcached_return> unless otherwise indicated.

=cut

=head1 EXPORTS

All the public functions in libmemcached are available for import.

All the public constants and enums in libmemcached are available for import.

Exporter tags are defined for each enum. This allows you to import groups of
constants easily. For example, to import all the contants for
memcached_behavior_set() and memcached_behavior_get(), you can use:

  use Memcached::libmemcached qw(:memcached_behavior).

=head1 FUNCTIONS

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

  memcached_free($memc); # void

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

See L<Memcached::libmemcached::memcached_set>.

=head3 memcached_set

  memcached_set($memc, $key, $value);
  memcached_set($memc, $key, $value, $expiration, $flags);

Set $value as the value of $key.
$expiration and $flags are both optional and default to 0.

=head3 memcached_append

  memcached_append($memc, $key, $value);
  memcached_append($memc, $key, $value, $expiration, $flags);

Append $value to the value of $key. $key must already exist.
$expiration and $flags are both optional and default to 0.

=head3 memcached_prepend

  memcached_prepend($memc, $key, $value)
  memcached_prepend($memc, $key, $value, $expiration, $flags)

Prepend $value to the value of $key. $key must already exist.
$expiration and $flags are both optional and default to 0.

=cut


=head2 Functions for Fetching Values from memcached

See L<Memcached::libmemcached::memcached_get>.

=head3 memcached_get

  $value = memcached_get($memc, $key, $flags, $rc);
  $value = memcached_get($memc, $key);

Get and return the value of $key.  Returns undef on error.

Also updates $flags to the value of the flags stored with $value,
and updates $rc with the return code.

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


=head2 Functions for Managing Results from memcached

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_result_st.pod

=cut


=head2 Functions for Deleting Values from memcached

See L<Memcached::libmemcached::memcached_delete>.

=head3 memcached_delete

  memcached_delete($memc, $key);
  memcached_delete($memc, $key, $expiration);

Delete $key. If $expiration is greater than zero then the key is deleted by
memcached after that many seconds.

=cut


=head2 Functions for Accessing Statistics from memcached

See L<Memcached::libmemcached::memcached_stats>.

=cut


=head2 Miscellaneous Functions

=head3 memcached_strerror

  $string = memcached_strerror($memc, $return_code)

memcached_strerror() takes a C<memcached_return> value and returns a string describing the error.
The string should be treated as read-only (it may be so in future versions).
See also L<Memcached::libmemcached::memcached_strerror>.

This function is rarely needed in the Perl interface because the return code is
a I<dualvar> that already contains the error string.

=cut



=head1 AUTHOR

Tim Bunce, C<< <Tim.Bunce@pobox.com> >> with help from Patrick Galbraith.

=head1 PORTABILITY

See Slaven Rezic's excellent CPAN Testers Matrix at L<http://bbbike.radzeit.de/~slaven/cpantestersmatrix.cgi?dist=Memcached-libmemcached>

Along with Dave Cantrell's excellent CPAN Dependency tracker at
L<http://cpandeps.cantrell.org.uk/?module=Memcached%3A%3Alibmemcached&perl=any+version&os=any+OS>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-memcached-libmemcached@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Memcached-libmemcached>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tim Bunce, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Memcached::libmemcached
