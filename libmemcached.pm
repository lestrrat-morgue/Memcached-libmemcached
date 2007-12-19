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

    my $foo = Memcached::libmemcached->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 new

Creates a new Memcached::libmemcached object.  ...

=cut

#sub new {
# Defined in the XS code
#}

=head2 set 

An object method which increments the 'value' slot of the the object hash,
if it exists.  Called like this:

  my $thing= {
      'candy' => 'chocolate',
      'drink' => 'milk', 
      'stuff' => ['abc', 'efg', 'hij'] };

  $obj->set('xyz', $thing); # set object in memcached, keyed by 'xyz' 


=cut

=head2 get 

An object method which increments the 'value' slot of the the object hash,
if it exists.  Called like this:

  $obj->get('xyz'); # retreive object from memcached, keyed by 'xyz' 


=cut

=head2 increment

An object method which increments the 'value' slot of the the object hash,
if it exists.  Called like this:

  my $obj = Memcached::libmemcached->new(5);
  $obj->increment(); # now equal to 6

  $obj->increment(10); # now equal to 16

=cut

=head2 decrement 

An object method which decrements the 'value' slot of the the object hash,
if it exists.  Called like this:

  my $obj = Memcached::libmemcached->new(5);
  $obj->decrement(); # now equal to 4 

  $obj->decrement(2); # now equal to 2 

=cut

#sub function2 {
# Defined in the XS code
#}

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
