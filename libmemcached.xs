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


/* ====================================================================================== */

MODULE=Memcached::libmemcached  PACKAGE=Memcached::libmemcached


=head2 Methods For Managing libmemcached Objects

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


=head2 Methods for Setting Values in memcached

Memcached__libmemcached__return
memcached_set(ptr, key, expiration= 0, flags= 0)
    Memcached__libmemcached ptr
    char *key
    time_t expiration
    uint16_t flags
  CODE:
    {
      size_t key_length = strlen(key);
      RETVAL = memcached_set(ptr, key, key_length, expiration, flags);
    }
  OUTPUT:
    RETVAL


=cut


=head2 Methods for Incrementing and Decrementing Values from memcached

=cut


=head2 Methods for Fetching Values from memcached

=cut


=head2 Methods for Managing Results from memcached

=cut


=head2 Methods for Deleting Values from memcached

=cut


=head2 Methods for Accessing Statistics from memcached

=cut


