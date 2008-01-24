package Memcached::libmemcached;

use warnings;
use strict;

=head1 NAME

Memcached::libmemcached - Thin fast full interface to the libmemcached client API

=head1 VERSION

Version 0.1401

=cut

our $VERSION = '0.1401';

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

=head2 Function Names and Arguments

The function names in this module are exactly the same as the functions in the
libmemcached library and documentation.

The function arguments are also the same as the libmemcached library and
documentation, with two exceptions:

* There are no I<length> arguments. Wherever the libmemcached documentation
shows a length argument (input or output) the corresponding argument doesn't
exist in the Perl API, because it's not needed.

* Some arguments are optional.

Many libmemcached function arguments are I<output values>: the argument is the
address of the value that the function will modify. For these the perl function
will modify the argument directly if it can. For example, in this call:

    $value = memcached_get($memc, $key, $flags, $rc);

The $flags and $rc arguments are output values that are modified by the
memcached_get() function.

See the L</Type Mapping> section for the fine detail of how each argument type
is handled.

=head2 Return Status

Most of the functions return an integer status value. This is shown as
C<memcached_return> in the libmemcached documentation.

In the perl interface this value is not returned directly. Instead a simple
boolean is returned: true for 'success', defined but false for some
'unsuccessfull' conditions, and undef for all other cases (i.e., errors).

All the functions documented below return this simple boolean value unless
otherwise indicated.

The actual C<memcached_return> integer value, and corresponding error message,
for the last libmemcached function call can be accessed via the
L</memcached_errstr> function.

=cut

=head1 EXPORTS

All the public functions in libmemcached are available for import.

All the public constants and enums in libmemcached are also available for import.

Exporter tags are defined for each enum. This allows you to import groups of
constants easily. For example, to enable consistent hashing you could use:

  use Memcached::libmemcached qw(:memcached_behavior :memcached_server_distribution);

  memcached_behavior_set($memc, MEMCACHED_BEHAVIOR_DISTRIBUTION(), MEMCACHED_DISTRIBUTION_CONSISTENT());

The L<Exporter> module allows patterns in the import list, so to import all the
functions, for example, you can use:

  use Memcached::libmemcached qw(/^memcached/);


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

=head3 memcached_errstr

  $errstr = memcached_errstr($memc);

Returns the error message and code from the most recent call to any
libmemcached function that returns a C<memcached_return>, which most do.

The return value is a I<dualvar>, like $!, which means it has separate numeric
and string values. The numeric value is the memcached_return integer value,
and the string value is the corresponding error message what memcached_strerror()
would return.

As a special case, if the memcached_return is MEMCACHED_ERRNO, indicating a
system call error, then the string returned by strerror() is appended.

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

=head3 memcached_replace

  memcached_replace($memc, $key, $value)
  memcached_replace($memc, $key, $value, $expiration, $flags)

Replace with $value the existing value of the value stored with
$key. $key must already exist.  $expiration and $flags are both
optional and default to 0.

=head3 memcached_cas

  memcached_cas($memc, $key, $value, $expiration, $flags, $cas)

Overwrites data in the server stored as $key as long as $cas
is still the same in the server. Cas is still buggy in memached.
Turning on support for it in libmemcached is optional.
Please see memcached_behavior_set() for information on how to do this.

XXX and the memcached_result_cas() function isn't implemented yet
so you can't get the $cas to use.

=cut


=head2 Functions for Fetching Values from memcached

See L<Memcached::libmemcached::memcached_get>.

=head3 memcached_get

  $value = memcached_get($memc, $key);
  $value = memcached_get($memc, $key, $flags, $rc);

Get and return the value of $key.  Returns undef on error.

Also updates $flags to the value of the flags stored with $value,
and updates $rc with the return code.

=head3 memcached_mget

  memcached_mget($memc, \@keys);
  memcached_mget($memc, \%keys);

Triggers the asynchronous fetching of multiple keys at once. For multiple key
operations it is always faster to use this function. You I<must> then use
memcached_fetch() or memcached_fetch_result() to retrieve any keys found.
No error is given on keys that are not found.

Instead of this function, you'd normally use L</memcached_mget_into_hashref>.

=head3 memcached_mget_into_hashref

  memcached_mget_into_hashref($memc, $keys_ref, \%dest_hash);

Combines memcached_mget() and a memcached_fetch() loop into a single highly
efficient call.

Fetched values are stored in \%dest_hash, updating existing values or adding
new ones as appropriate.

=head3 memcached_fetch

  $value = memcached_fetch($memc, $key);
  $value = memcached_fetch($memc, $key, $flag, $rc);

Fetch the next $key and $value pair returned in response to a memcached_mget() call.
Returns undef if there are no more values.

If $flag is given then it will be updated to whatever flags were stored with the value.
If $rc is given then it will be updated to the return code.

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

=head3 memcached_set_callback_coderefs

  memcached_set_callback_coderefs($memc, \&set_callback, \&get_callback);

This interface is I<experimental> and I<likely to change>.
Currently only the get calback works.

Specify functions which will be executed when values are set and/or get using $memc. 

When the callbacks are executed $_ is the value and the arguments are the key
and flags value. Both $_ and the flags may be modified.

Currently the functions must return an empty list.

=cut

=head2 Unsupported Functions

=head3 memcached_cas 
=cut

=head3 (stats)   
=cut

=head3 (disconnect/quit)
=cut

=head3 memcached_flush 
=cut

=head3 memcached_replace
=cut


=head1 EXTRA INFORMATION

=head2 Tracing Execution

The C<PERL_LIBMEMCACHED_TRACE> environment variable can be used to control
tracing. The value is read when L<memcached_create> is called.

If set >= 1 then any non-success memcached_return value will be logged via warn().

If set >= 2 or more then some data types will list conversions of input and output values for function calls.

More flexible mechanisms will be added later.

=head2 Type Mapping

For pointer arguments, undef is mapped to null on input and null is mapped to
undef on output.

XXX expand with details from typemap file

=head1 AUTHOR

Tim Bunce, C<< <Tim.Bunce@pobox.com> >> with help from Patrick Galbraith.

L<http://www.tim.bunce.name>

=head1 ACKNOWLEDGEMENTS

Larry Wall for Perl, Brad Fitzpatrick for memcached, Brian Aker for libmemcached,
and Patrick Galbraith for helping with the implementation.

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

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tim Bunce, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Memcached::libmemcached
