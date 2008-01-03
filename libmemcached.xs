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
typedef memcached_server_st* Memcached__libmemcached__server_list;
typedef memcached_st*        Memcached__libmemcached;


/* ====================================================================================== */

MODULE=Memcached::libmemcached  PACKAGE=Memcached::libmemcached



=head2 Methods For Managing Server Lists

=cut

Memcached__libmemcached__server_list
memcached_servers_parse(char *server_strings)


unsigned int
memcached_server_list_count(Memcached__libmemcached__server_list ptr);


void
memcached_server_list_append(...)
    PPCODE:
    croak("memcached_server_list_append is deprecated");


void
memcached_server_list_free(Memcached__libmemcached__server_list ptr)
    INIT:
        if (!ptr) /* already freed this sv */
            XSRETURN_EMPTY;
    POSTCALL:
        if (ptr) {
            /* avoid duplicate free errors for the same SV.     */
            /* doesn't prevent duplicate free from diferent SVs */
            sv_setiv((SV*)SvRV(ST(0)), 0);
        }


=head2 Methods For Managing libmemcached Objects

=cut

Memcached__libmemcached
memcached_create(Memcached__libmemcached ptr)

Memcached__libmemcached
memcached_clone(Memcached__libmemcached clone, Memcached__libmemcached source)

Memcached__libmemcached__return
memcached_increment(Memcached__libmemcached ptr, char *key, size_t length(key), unsigned int offset, uint64_t &value=NO_INIT)

Memcached__libmemcached__return
memcached_decrement(Memcached__libmemcached ptr, char *key, size_t length(key), unsigned int offset, uint64_t &value=NO_INIT)


unsigned int
memcached_server_count(Memcached__libmemcached ptr)

Memcached__libmemcached__server_list
memcached_server_list(Memcached__libmemcached ptr)

Memcached__libmemcached__return
memcached_server_add(Memcached__libmemcached ptr, char *hostname, unsigned int port=0)

Memcached__libmemcached__return
memcached_server_add_unix_socket (Memcached__libmemcached ptr, char *socket)

Memcached__libmemcached__return
memcached_server_push(Memcached__libmemcached ptr, Memcached__libmemcached__server_list list)

void
memcached_free(Memcached__libmemcached ptr)
    INIT:
        if (!ptr) /* already freed this sv */
            XSRETURN_EMPTY;
    POSTCALL:
        warn("memcached_free");
        if (ptr) {
            /* avoid duplicate free errors for the same SV.     */
            /* doesn't prevent duplicate free from diferent SVs */
            sv_setiv((SV*)SvRV(ST(0)), 0);
        }



=head2 Methods for Setting Values in memcached

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


