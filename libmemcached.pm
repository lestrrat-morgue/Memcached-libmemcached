package Memcached::libmemcached;

use warnings;
use strict;

=head1 NAME

Memcached::libmemcached - Thin fast interface to the libmemcached client API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Memcached::libmemcached', $VERSION);

=head1 SYNOPSIS

  use Memcached::libmemcached;

  my $memc = Memcached::libmemcached->create();
  $memc->server_push($servers);

=head1 EXPORT


=head1 METHODS

=head2 Conventions

Memcached::libmemcached is a very thin wrapper around the libmemcached library.
The libmemcached library documentation (which is bundled with
Memcached::libmemcached) serves as the primary reference for the functionality.

This documentation aims to provide just a summary of the methods, along with
any issues specific to this perl interface.

=head3 Classes

The functions in the libmemcached library have been grouped into classes in
this perl interface based on the type of the first argument:

  Type                  Class
  -------------------   ----------------
  memcached_st          Memcached::libmemcached
  memcached_server_st   Memcached::libmemcached::servers
  memcached_result_st   Memcached::libmemcached::result

Currently all the classes are documented here.
Some documentation may be broken out into other files later.

=head3 Arguments

For structure pointer arguments, undef is mapped to null on input and null is
mapped to undef on output. (Also, as a slightly bizarre special case, on input a
string matching the class name, or any class derived from it, is treated as null.
That's how static method calls like Memcached::libmemcached->create work.)

=head2 Return

Most of the methods return an integer status value. This is shown as
memcached_return in the libmemcached documentation. 

TODO: make a dual-var with integer and string parts (via typemap)

=cut


=head2 Methods For Managing Server Lists

=head3 XXX

fill out docs for Memcached::libmemcached::servers methods

=cut


=head2 Methods For Managing libmemcached Objects

=head3 create

  my $memc = Memcached::libmemcached->create();

Creates and returns a new Memcached::libmemcached object.
See L<Memcached::libmemcached::memcached_create>.

=head3 server_push

  $memc->server_push($server_list_object);

Adds a list of servers to the libmemcached object.
See L<Memcached::libmemcached::memcached_create>.

=head3 server_count

  $server_count= $memc->server_count();

Returns a count of the current number of servers
associated with $memc.

=head3 server_list

  $server_list= $memc->server_list();

Returns the L<Memcached::libmemcached::servers> object associated with $memc.
(Don't call 

=head3 server_add

  $memc->server_add($hostname, $port);

Pushes a single memcached server into the memcached object

=head3 server_add_unix_socket

  $memc->server_add_unix_socket($socket);

Pushes a single UNIX socket into the memcached object

=head3 behavior_set

  $memc->behavior_set($option_key, $option_value);

Changes the value of a particular option.
See L<Memcached::libmemcached::memcached_behavior>.

=head3 behavior_get

  $memc->behavior_get($option_key);

Get the value of a particular option.
See L<Memcached::libmemcached::memcached_behavior>.

=head3 verbosity

  $memc->verbosity($verbosity)

Modifies the "verbosity" of the associated memcached servers.
See L<Memcached::libmemcached::memcached_verbosity>.

=head3 flush

  $memc->flush($expiration);

Wipe clean the contents of associated memcached servers.
See L<Memcached::libmemcached::memcached_flush>.

=head3 quit

  $memc->quit();

Disconnect from all currently connected servers and reset state.
Not normally called explicitly.
See L<Memcached::libmemcached::memcached_quit>.

=cut


=head2 Methods for Setting Values in memcached

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_set.pod

=cut


=head2 Methods for Incrementing and Decrementing Values from memcached

=head3 increment

  $return = $memc->increment( $key, $offset, $new_value_out );

Increments the value associated with $key by $offset and returns the new value in $new_value_out.
See also L<Memcached::libmemcached::memcached_auto>.

=head3 decrement 

  $memc->decrement( $key, $offset, $new_value_out );

Decrements the value associated with $key by $offset and returns the new value in $new_value_out.
See also L<Memcached::libmemcached::memcached_auto>.

=cut


=head2 Methods for Fetching Values from memcached

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_get.pod

=cut


=head2 Methods for Managing Results from memcached

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_result_st.pod

=cut


=head2 Methods for Deleting Values from memcached

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_delete.pod

=cut


=head2 Methods for Accessing Statistics from memcached

XXX http://hg.tangent.org/libmemcached/file/4001ba159d62/docs/memcached_stats.pod

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
