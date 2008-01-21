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
typedef char*                lmc_key;
typedef char*                lmc_value;

/* XXX quick hack for now */
#define TRACE_MEMCACHED(ptr) \
    getenv("PERL_MEMCACHED_TRACE")

#define RECORD_RETURN_ERR(ptr, ret)

static memcached_return
_prep_keys_lengths(memcached_st *ptr, SV *keys_rv, char ***out_keys, size_t **out_key_length, unsigned int *out_number_of_keys)
{
    SV *keys_sv;
    unsigned int number_of_keys;
    char **keys;
    size_t *key_length;
    int i = 0;

    if (!SvROK(keys_rv))
        return MEMCACHED_NO_KEY_PROVIDED;
    keys_sv = SvRV(keys_rv);
    if (SvRMAGICAL(keys_rv)) /* disallow tied arrays for now */
        return MEMCACHED_NO_KEY_PROVIDED;

    if (SvTYPE(keys_sv) == SVt_PVAV) {
        number_of_keys = AvFILL(keys_sv)+1;
        Newx(keys,       number_of_keys, char *);
        Newx(key_length, number_of_keys, size_t);
        for (i = 0; i < number_of_keys; i++) {
            keys[i] = SvPV(AvARRAY(keys_sv)[i], key_length[i]);
        }
    }
    else if (SvTYPE(keys_sv) == SVt_PVHV) {
        HE *he;
        I32 retlen;
        hv_iterinit((HV*)keys_sv);
        number_of_keys = HvKEYS(keys_sv);
        Newx(keys,       number_of_keys, char *);
        Newx(key_length, number_of_keys, size_t);
        while ( (he = hv_iternext_flags((HV*)keys_sv, 0)) ) {
            keys[i] = hv_iterkey(he, &retlen);
            key_length[i++] = retlen;
        }
    }
    else {
        return MEMCACHED_NO_KEY_PROVIDED;
    }
    *out_number_of_keys = number_of_keys;
    *out_keys           = keys;
    *out_key_length     = key_length;
    return MEMCACHED_SUCCESS;
}


static memcached_return
_fetch_all_hashref(memcached_st *ptr, HV *dest_ref)
{
    memcached_return rc = MEMCACHED_MAXIMUM_RETURN; /* should never be returned */

    while (1) {
        char key[MEMCACHED_MAX_KEY];
        size_t key_length;
        char *value;
        size_t value_length;
        uint32_t flags = 0;
        SV **svp;

        value = memcached_fetch(ptr, key, &key_length, &value_length, &flags, &rc);
        if (value == NULL)
            break;

        svp = hv_fetch(dest_ref, key, key_length, 1);
        sv_setpvn(*svp, value, value_length);
    }

    return rc;
}



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
    ALIAS:
        DESTROY = 1
    INIT:
        if (!ptr)   /* garbage or already freed this sv */
            XSRETURN_EMPTY;
        PERL_UNUSED_VAR(ix);
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
        OUT lmc_data_flags_t flags=0, \
        OUT memcached_return error=0)
    PREINIT:
        size_t value_length=0;
    CODE:
        RETVAL = memcached_get(ptr, key, XSauto_length_of_key, &value_length, &flags, &error);
    OUTPUT:
        RETVAL



memcached_return
memcached_mget(Memcached__libmemcached ptr, SV *keys_rv)
    PREINIT:
        char **keys;
        size_t *key_length;
        unsigned int number_of_keys;
    CODE:
        if ((RETVAL = _prep_keys_lengths(ptr, keys_rv, &keys, &key_length, &number_of_keys)) == MEMCACHED_SUCCESS) {
            RETVAL = memcached_mget(ptr, keys, key_length, number_of_keys);
            Safefree(keys);
            Safefree(key_length);
        }
    OUTPUT:
        RETVAL

memcached_return
memcached_mget_into_hashref(Memcached__libmemcached ptr, SV *keys_ref, HV *dest_ref)
    PREINIT:
        char **keys;
        size_t *key_length;
        unsigned int number_of_keys;
    CODE:
        memcached_return ret;
        if ((ret = _prep_keys_lengths(ptr, keys_ref, &keys, &key_length, &number_of_keys)) == MEMCACHED_SUCCESS) {
            ret = memcached_mget(ptr, keys, key_length, number_of_keys);
            Safefree(keys);
            Safefree(key_length);
            if (ret == MEMCACHED_SUCCESS) {
                RETVAL = _fetch_all_hashref(ptr, dest_ref);
            }
        }
    OUTPUT:
        RETVAL



lmc_value
memcached_fetch(Memcached__libmemcached ptr, \
        OUT lmc_key key, \
        OUT lmc_data_flags_t flags=0, \
        OUT memcached_return error=0)
    PREINIT:
        size_t key_length=0;
        size_t value_length=0;
    INIT: 
        char key_buffer[MEMCACHED_MAX_KEY];
        key = key_buffer;
    CODE:
        RETVAL = memcached_fetch(ptr, key, &key_length, &value_length, &flags, &error);
    OUTPUT:
        RETVAL




=head2 Functions for Managing Results from memcached
/*
memcached_result_st *
memcached_fetch_result(Memcached__libmemcached ptr,\
                       memcached_result_st *result,\
                       memcached_return *error)
*/

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

SV *
_memcached_version(Memcached__libmemcached ptr)
    PREINIT:
        memcached_return memcached_version(memcached_st *); /* declare memcached_version */
    PPCODE:
        /* memcached_version updates ptr->hosts[x].*_version for each
         * associated memcached server that responds to the request.
         * We use it internally as both a kind of ping and to check
         * the min version for testing version-specific features.
         */
        /* XXX internal undocumented api */
        RETVAL = 0; /* avoid unused warning */
        if (memcached_version(ptr) != MEMCACHED_SUCCESS)
            XSRETURN_EMPTY;
        /* XXX assumes first entry in list of hosts responded
         * and that any other memcached servers have the same version
         */
        mXPUSHi(ptr->hosts[0].major_version);
        mXPUSHi(ptr->hosts[0].minor_version);
        mXPUSHi(ptr->hosts[0].micro_version);
        XSRETURN(3);
