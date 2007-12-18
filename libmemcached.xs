/*
 * vim: expandtab:sw=4
 * */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libmemcached/memcached.h>

/* mapping C types to perl classes - see typemap file */
typedef memcached_return     Memcached_libmemcached_return;
typedef memcached_server_st* Memcached_libmemcached_servers;
typedef memcached_st*        Memcached_libmemcached;


MODULE=Memcached::libmemcached  PACKAGE=Memcached::libmemcached::servers  PREFIX=memcached_

Memcached_libmemcached_servers
memcached_servers_parse(SV *self, char *server_strings)
    C_ARGS:
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


MODULE=Memcached::libmemcached  PACKAGE=Memcached::libmemcached  PREFIX=memcached_

Memcached_libmemcached
memcached_create(Memcached_libmemcached ptr)

Memcached_libmemcached
memcached_clone(Memcached_libmemcached clone, Memcached_libmemcached source)

void
memcached_free(Memcached_libmemcached ptr)
    ALIAS:
        DESTROY = 1
    POSTCALL:
        /* avoid duplicate free errors - XXX hack */
        warn("memcached_free");
        sv_setiv((SV*)SvRV(ST(0)), 0);

