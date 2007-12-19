/*
 * vim: expandtab:sw=4
 * */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libmemcached/memcached.h>

/* mapping C types to perl classes - keep typemap file in sync */
typedef memcached_return     Memcached_libmemcached_return;
typedef memcached_behavior   Memcached_libmemcached_behavior;
typedef memcached_server_st* Memcached_libmemcached_servers;
typedef memcached_st*        Memcached_libmemcached;


/* ====================================================================================== */


=head2 Methods For Managing Server Lists

=cut

MODULE=Memcached::libmemcached  PACKAGE=Memcached::libmemcached::servers  PREFIX=memcached_

Memcached_libmemcached_servers
memcached_servers_parse(void *self, char *server_strings)
    C_ARGS: /* self is not used  */
        server_strings


unsigned int
memcached_server_list_count(Memcached_libmemcached_servers ptr);


Memcached_libmemcached_servers
memcached_server_list_append(ptr, hostname, port, error)
    Memcached_libmemcached_servers ptr
    char *hostname
    unsigned int port
    Memcached_libmemcached_return &error = NO_INIT
    OUTPUT:
        error


void
memcached_server_list_free(Memcached_libmemcached_servers ptr)
    ALIAS:
        DESTROY = 1
    POSTCALL:
        /* avoid duplicate free errors - XXX hack */
        warn("memcached_server_list_free");
        sv_setiv((SV*)SvRV(ST(0)), 0);




=head2 Methods For Managing libmemcached Objects

=cut

MODULE=Memcached::libmemcached  PACKAGE=Memcached::libmemcached  PREFIX=memcached_

Memcached_libmemcached
memcached_create(Memcached_libmemcached ptr)

Memcached_libmemcached
memcached_clone(Memcached_libmemcached clone, Memcached_libmemcached source)

Memcached_libmemcached_return
memcached_increment(Memcached_libmemcached ptr, char *key, size_t length(key), unsigned int offset, uint64_t &value=NO_INIT)

Memcached_libmemcached_return
memcached_decrement(Memcached_libmemcached ptr, char *key, size_t length(key), unsigned int offset, uint64_t &value=NO_INIT)

void
memcached_free(Memcached_libmemcached ptr)
    ALIAS:
        DESTROY = 1
    POSTCALL:
        /* avoid duplicate free errors - XXX hack */
        warn("memcached_free");
        sv_setiv((SV*)SvRV(ST(0)), 0);



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


