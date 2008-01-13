/*
 * vim: expandtab:sw=4
 * */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libmemcached/memcached.h>

/* mapping C types to perl classes - keep typemap file in sync */
typedef memcached_return     Memcached__libmemcached__return;
typedef memcached_behavior   Memcached__libmemcached__behavior;
typedef memcached_st*        Memcached__libmemcached;

#include "const-c.inc"

/* ====================================================================================== */

MODULE=Memcached::libmemcached  PACKAGE=Memcached::libmemcached

INCLUDE: const-xs.inc


=head2 Functions For Managing libmemcached Objects

=cut

Memcached__libmemcached
memcached_create(Memcached__libmemcached ptr=NULL)
    INIT:
        ptr = NULL; /* force null even if arg provided */


Memcached__libmemcached
memcached_clone(Memcached__libmemcached clone, Memcached__libmemcached source)
    INIT:
        clone = NULL; /* force null even if arg provided */


Memcached__libmemcached__return
memcached_increment(Memcached__libmemcached ptr, char *key, size_t length(key), unsigned int offset, uint64_t &value=NO_INIT)

Memcached__libmemcached__return
memcached_decrement(Memcached__libmemcached ptr, char *key, size_t length(key), unsigned int offset, uint64_t &value=NO_INIT)


unsigned int
memcached_server_count(Memcached__libmemcached ptr)

Memcached__libmemcached__return
memcached_server_add(Memcached__libmemcached ptr, char *hostname, unsigned int port=0)

Memcached__libmemcached__return
memcached_server_add_unix_socket(Memcached__libmemcached ptr, char *socket)

void
memcached_free(Memcached__libmemcached ptr)
    INIT:
        if (!ptr)   /* garbage or already freed this sv */
            XSRETURN_EMPTY;
    POSTCALL:
        if (ptr)    /* mark as undef to avoid duplicate free */
            SvOK_off((SV*)SvRV(ST(0)));


=head2 Functions for Setting Values in memcached

Memcached__libmemcached__return
memcached_set(Memcached__libmemcached ptr, char *key, size_t length(key), char *value, size_t length(value), time_t expiration= 0, uint16_t flags= 0)


=cut


=head2 Functions for Incrementing and Decrementing Values from memcached

=cut


=head2 Functions for Fetching Values from memcached

=cut


=head2 Functions for Managing Results from memcached

=cut


=head2 Functions for Deleting Values from memcached

=cut


=head2 Functions for Accessing Statistics from memcached

=cut


=head2 Miscellaneous Functions

=cut

char *
memcached_strerror(Memcached__libmemcached ptr, Memcached__libmemcached__return rc)
