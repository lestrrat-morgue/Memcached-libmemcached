/*
 * vim: expandtab:sw=4
 * */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libmemcached/memcached.h>

/* mapping C types to perl classes - keep typemap file in sync */
typedef memcached_st*        Memcached__libmemcached;
typedef uint32_t             lmc_data_flags_t;
typedef char*                lmc_value;

/* XXX quick hack for now */
#define TRACE_MEMCACHED(ptr) \
    getenv("PERL_MEMCACHED_TRACE")

/* ====================================================================================== */

MODULE=Memcached::libmemcached  PACKAGE=Memcached::libmemcached

PROTOTYPES: DISABLED

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


unsigned int
memcached_server_count(Memcached__libmemcached ptr)

memcached_return
memcached_server_add(Memcached__libmemcached ptr, char *hostname, unsigned int port=0)

memcached_return
memcached_server_add_unix_socket(Memcached__libmemcached ptr, char *socket)

void
memcached_free(Memcached__libmemcached ptr)
    INIT:
        if (!ptr)   /* garbage or already freed this sv */
            XSRETURN_EMPTY;
    POSTCALL:
        if (ptr)    /* mark as undef to avoid duplicate free */
            SvOK_off((SV*)SvRV(ST(0)));

UV
memcached_behavior_get(Memcached__libmemcached ptr, memcached_behavior flag)

memcached_return
memcached_behavior_set(Memcached__libmemcached ptr, memcached_behavior flag, void *data)
    INIT:
        /* catch any special cases */
        if (flag == MEMCACHED_BEHAVIOR_USER_DATA) {
            XSRETURN_IV(MEMCACHED_FAILURE);
        }
        data = (SvTRUE(ST(2))) ? (void*)1 : (void*)0;
        if (data && strNE(SvPV_nolen(ST(2)),"1")) {
            warn("memcached_behavior_set currently only supports boolean behaviors");
        }   



=head2 Functions for Setting Values in memcached

=cut

memcached_return
memcached_set(Memcached__libmemcached ptr, char *key, size_t length(key), char *value, size_t length(value), time_t expiration= 0, lmc_data_flags_t flags= 0)


memcached_return
memcached_append(Memcached__libmemcached ptr, char *key, size_t length(key), char *value, size_t length(value), time_t expiration= 0, lmc_data_flags_t flags=0)

memcached_return
memcached_prepend(Memcached__libmemcached ptr, char *key, size_t length(key), char *value, size_t length(value), time_t expiration= 0, lmc_data_flags_t flags=0)



=head2 Functions for Incrementing and Decrementing Values from memcached

=cut

memcached_return
memcached_increment(Memcached__libmemcached ptr, char *key, size_t length(key), unsigned int offset, IN_OUT uint64_t value=NO_INIT)

memcached_return
memcached_decrement(Memcached__libmemcached ptr, char *key, size_t length(key), unsigned int offset, IN_OUT uint64_t value=NO_INIT)





=head2 Functions for Fetching Values from memcached

=cut

lmc_value
memcached_get(Memcached__libmemcached ptr, \
        char *key, size_t length(key), \
        IN_OUT lmc_data_flags_t flags, \
        IN_OUT memcached_return error)
    PREINIT:
        size_t value_length=0;
    CODE:
        RETVAL = memcached_get(ptr, key, XSauto_length_of_key, &value_length, &flags, &error);
    OUTPUT:
        RETVAL

=head2 Function Patrick is trying to figure out
/*
memcached_return
memcached_mget(Memcached__libmemcached ptr, char **keys, size_t *key_length, unsigned int number_of_keys)
    PREINIT:
      number_of_keys= items - 1;
      int i;
    CODE:
        Newxz(keys, number_of_keys, char *);
        Newxz(key_length, number_of_keys, size_t);

        for (i = 0; i < number_of_keys; i++) {
            keys[i] = SvPV(ST(i + 1), key_length[i]);
        }
        Safefree(keys);
        Safefree(key_length);
    OUTPUT:
        RETVAL
*/
=cut





=head2 Functions for Managing Results from memcached

=cut


=head2 Functions for Deleting Values from memcached

=cut

memcached_return
memcached_delete(Memcached__libmemcached ptr, char *key, size_t length(key), time_t expiration= 0)



=head2 Functions for Accessing Statistics from memcached

=cut


=head2 Miscellaneous Functions

=cut

char *
memcached_strerror(Memcached__libmemcached ptr, memcached_return rc)
