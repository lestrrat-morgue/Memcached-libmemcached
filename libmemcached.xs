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
typedef time_t               lmc_expiration;

/* XXX quick hack for now */
#define LMC_STATE(ptr) \
    ((lmc_state_st*)memcached_callback_get(ptr, MEMCACHED_CALLBACK_USER_DATA, NULL))
#define LMC_TRACE_LEVEL(ptr) \
    ((ptr) ? LMC_STATE(ptr)->trace_level : 0)
#define LMC_RETURN_OK(ret) \
    (ret==MEMCACHED_SUCCESS || ret==MEMCACHED_END || ret==MEMCACHED_BUFFERED)

#define RECORD_RETURN_ERR(ptr, ret) \
    STMT_START {    \
        lmc_state_st* lmc_state = LMC_STATE(ptr); \
        lmc_state->last_return = ret;   \
        lmc_state->last_errno  = ptr->cached_errno; /* if MEMCACHED_ERRNO */ \
    } STMT_END


/* ====================================================================================== */


typedef struct lmc_state_st lmc_state_st;
typedef struct lmc_cb_context_st lmc_cb_context_st;

/* context information for callbacks */
struct lmc_cb_context_st {
    lmc_state_st *lmc_state;
    SV *dest_sv;
    HV *dest_hv;
    memcached_return *rc_ptr;
    lmc_data_flags_t *flags_ptr;
    UV  result_count;
    SV  *get_cb;
    SV  *set_cb;
};

/* perl api state information associated with an individual memcached_st */
struct lmc_state_st {
    int              trace_level;
    int              options;
    memcached_return last_return;
    int              last_errno;
    /* handy default fetch context for fetching single items */
    lmc_cb_context_st *cb_context; /* points to _cb_context by default */
    lmc_cb_context_st _cb_context;
};


static lmc_state_st *
lmc_state_new(SV *memc_sv)
{
    char *trace = getenv("PERL_LIBMEMCACHED_TRACE");
    lmc_state_st *lmc_state;
    Newz(0, lmc_state, 1, struct lmc_state_st);
    lmc_state->cb_context = &lmc_state->_cb_context;
    lmc_state->cb_context->lmc_state = lmc_state;
    lmc_state->cb_context->set_cb = newSV(0);
    lmc_state->cb_context->get_cb = newSV(0);
    if (trace) {
        lmc_state->trace_level = atoi(trace);
    }
    return lmc_state;
}

static void
lmc_state_cleanup(memcached_st *ptr)
{
    lmc_state_st *lmc_state = 0;
    memcached_return rc;
    lmc_state = memcached_callback_get(ptr, MEMCACHED_CALLBACK_USER_DATA, &rc);
    memcached_callback_set(ptr, MEMCACHED_CALLBACK_USER_DATA, 0);
    if (lmc_state->trace_level >= 2)
        warn("lmc_state_cleanup(%p) %p", ptr, lmc_state);

    sv_free(lmc_state->cb_context->get_cb);
    sv_free(lmc_state->cb_context->set_cb);
    Safefree(lmc_state);
}


/* ====================================================================================== */


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


/* ====================================================================================== */

/* --- callbacks for memcached_fetch_execute ---
 */

static unsigned int
_cb_prep_store_into_sv_of_hv(memcached_st *ptr, memcached_result_st *result, void *context)
{
    /* Set dest_sv to the appropriate sv in dest_hv              */
    /* Called before _cb_store_into_sv when fetching into a hash */
    lmc_cb_context_st *lmc_cb_context = context;
    SV **svp = hv_fetch( lmc_cb_context->dest_hv, memcached_result_key_value(result), memcached_result_key_length(result), 1);
    lmc_cb_context->dest_sv = *svp;
    return 0;
}

static unsigned int
_cb_store_into_sv(memcached_st *ptr, memcached_result_st *result, void *context) 
{
    /* Store result value and flags into places specified by lmc_cb_context */
    /* This is the 'core' fetch callback. Increments result_count.             */
    lmc_cb_context_st *lmc_cb_context = context;
    ++lmc_cb_context->result_count;
    *lmc_cb_context->flags_ptr = memcached_result_flags(result);
    sv_setpvn(lmc_cb_context->dest_sv, memcached_result_value(result), memcached_result_length(result));
    return 0;
}


/* XXX - Notes:
 * Perl callbacks are called as
 *
 *    sub {
 *      my ($key, $flags) = @_;  # with $_ containing the value
 *    }
 *
 * Modifications to $_ (value) and $_[1] (flags) propagate to other callbacks,
 * and thus to libmemcached.
 * Callbacks can't recurse within the same $memc at the moment.
 */
static unsigned int
_cb_fire_perl_cb(lmc_cb_context_st *lmc_cb_context, SV *callback_sv, SV *key_sv, SV *value_sv, SV *flags_sv)
{       
    int items;
    dSP;

    ENTER;
    SAVETMPS;

    SAVE_DEFSV; /* local($_) = $value */
    DEFSV = value_sv;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(key_sv);
    PUSHs(flags_sv);
    PUTBACK;

    items = call_sv(callback_sv, G_ARRAY);
    SPAGAIN;

    if (items) /* may use returned items for signalling later */
        croak("fetch callback returned non-empty list");

    FREETMPS;
    LEAVE;
    return 0;
}


static unsigned int
_cb_fire_perl_set_cb(memcached_st *ptr, SV *key_sv, SV *value_sv, SV *flags_sv)
{
    /* XXX note different api to _cb_fire_perl_get_cb */
    lmc_state_st *lmc_state = LMC_STATE(ptr);
    lmc_cb_context_st *lmc_cb_context = lmc_state->cb_context;
    unsigned int status;

    if (!SvOK(lmc_cb_context->set_cb))
        return 0;

    status = _cb_fire_perl_cb(lmc_cb_context, lmc_cb_context->set_cb, key_sv, value_sv, flags_sv);
    return status;
}

static unsigned int
_cb_fire_perl_get_cb(memcached_st *ptr, memcached_result_st *result, void *context)
{
    /* designed to be called via memcached_fetch_execute() */
    lmc_cb_context_st *lmc_cb_context = context;
    SV *key_sv, *value_sv, *flags_sv;
    unsigned int status;

    if (!SvOK(lmc_cb_context->get_cb))
        return 0;

    /* these SVs may get cached inside lmc_cb_context_st and reused across calls */
    /* which would save the create,mortalize,destroy costs for each invocation  */
    key_sv   = sv_2mortal(newSVpv(memcached_result_key_value(result), memcached_result_key_length(result)));
    value_sv = lmc_cb_context->dest_sv;
    flags_sv = sv_2mortal(newSVuv(*lmc_cb_context->flags_ptr));
    SvREADONLY_on(key_sv); /* just to be sure for now, may allow later */

    status = _cb_fire_perl_cb(lmc_cb_context, lmc_cb_context->get_cb, key_sv, value_sv, flags_sv);
    /* recover potentially modified values */
    *lmc_cb_context->flags_ptr = SvUV(flags_sv);

    return status;
}


/* ====================================================================================== */

static memcached_return
_fetch_all_hashref(memcached_st *ptr, memcached_return rc, HV *dest_ref)
{
    lmc_cb_context_st *lmc_cb_context;
    lmc_data_flags_t flags;
    unsigned int (*callback[])(memcached_st *ptr, memcached_result_st *result, void *context) = {
        _cb_prep_store_into_sv_of_hv,
        _cb_store_into_sv,
        _cb_fire_perl_get_cb,
    };

    /* rc is the return code from the preceeding mget */
    if (!LMC_RETURN_OK(rc)) {
        if (rc == MEMCACHED_NOTFOUND) {
            /* when number_of_keys==0 memcached_mget returns MEMCACHED_NOTFOUND
            * which we'd normally translate into a false return value
            * but that's not really appropriate here
            */
            return MEMCACHED_SUCCESS;
        }
        return rc;
    }

    lmc_cb_context = LMC_STATE(ptr)->cb_context;
    lmc_cb_context->dest_hv   = dest_ref;
    lmc_cb_context->flags_ptr = &flags;  /* local, not returned to caller */
    lmc_cb_context->rc_ptr    = &rc;     /* local, not returned to caller */
    lmc_cb_context->result_count = 0;

    return memcached_fetch_execute(ptr, callback, (void *)lmc_cb_context, 3);
}


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
memcached_set(Memcached__libmemcached ptr, \
        lmc_key   key,   size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration= 0, lmc_data_flags_t flags= 0)

memcached_return
memcached_set_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key   key,      size_t length(key), \
        lmc_value value,    size_t length(value), \
        lmc_expiration expiration=0, lmc_data_flags_t flags=0)

memcached_return
memcached_add (Memcached__libmemcached ptr, \
        lmc_key   key,   size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration= 0, lmc_data_flags_t flags=0)

memcached_return
memcached_add_by_key(Memcached__libmemcached ptr, \
        lmc_key   master_key, size_t length(master_key), \
        lmc_key   key,        size_t length(key), \
        lmc_value value,      size_t length(value), \
        lmc_expiration expiration=0, lmc_data_flags_t flags=0)

memcached_return
memcached_append(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key),\
        lmc_value value, size_t length(value),\
        lmc_expiration expiration= 0, lmc_data_flags_t flags=0)

memcached_return
memcached_append_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration=0, lmc_data_flags_t flags=0)

memcached_return
memcached_prepend(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration= 0, lmc_data_flags_t flags=0)

memcached_return
memcached_prepend_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration=0, lmc_data_flags_t flags=0)

memcached_return
memcached_replace(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration= 0, lmc_data_flags_t flags=0)

memcached_return
memcached_replace_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration=0, lmc_data_flags_t flags=0)

memcached_return
memcached_cas(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration= 0, lmc_data_flags_t flags=0, uint64_t cas)


=head2 Functions for Incrementing and Decrementing Values from memcached

=cut

memcached_return
memcached_increment(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        unsigned int offset, IN_OUT uint64_t value=NO_INIT)

memcached_return
memcached_decrement(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        unsigned int offset, IN_OUT uint64_t value=NO_INIT)





=head2 Functions for Fetching Values from memcached

=cut

SV *
memcached_get(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        IN_OUT lmc_data_flags_t flags=0, \
        IN_OUT memcached_return error=0)
    PREINIT:
        unsigned int (*callbacks[])(memcached_st *ptr, memcached_result_st *result, void *context) = {
            _cb_store_into_sv,
            _cb_fire_perl_get_cb,
        };
        lmc_cb_context_st *lmc_cb_context;
    CODE:
        /* rc is the return code from the preceeding mget */
        error = memcached_mget_by_key(ptr, NULL, 0, &key, &XSauto_length_of_key, 1);
        lmc_cb_context = LMC_STATE(ptr)->cb_context;
        lmc_cb_context->dest_sv   = newSV(0);
        lmc_cb_context->flags_ptr = &flags;
        lmc_cb_context->rc_ptr    = &error;
        lmc_cb_context->result_count = 0;
        error = memcached_fetch_execute(ptr, callbacks, lmc_cb_context, 2);
        if (lmc_cb_context->result_count == 0 && error == MEMCACHED_SUCCESS)
            error = MEMCACHED_NOTFOUND; /* to match memcached_get behaviour */
        RETVAL = lmc_cb_context->dest_sv;
    OUTPUT:
        RETVAL

SV *
memcached_get_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        IN_OUT lmc_data_flags_t flags=0, \
        IN_OUT memcached_return error=0)
    PREINIT:
        unsigned int (*callbacks[])(memcached_st *ptr, memcached_result_st *result, void *context) = {
            _cb_store_into_sv,
            _cb_fire_perl_get_cb,
        };
        lmc_cb_context_st *lmc_cb_context;
    CODE:
        /* rc is the return code from the preceeding mget */
        error = memcached_mget_by_key(ptr, master_key, XSauto_length_of_master_key, &key, &XSauto_length_of_key, 1);
        lmc_cb_context = LMC_STATE(ptr)->cb_context;
        lmc_cb_context->dest_sv   = newSV(0);
        lmc_cb_context->flags_ptr = &flags;
        lmc_cb_context->rc_ptr    = &error;
        lmc_cb_context->result_count = 0;
        error = memcached_fetch_execute(ptr, callbacks, lmc_cb_context, 2);
        if (lmc_cb_context->result_count == 0 && error == MEMCACHED_SUCCESS)
            error = MEMCACHED_NOTFOUND; /* to match memcached_get behaviour */
        RETVAL = lmc_cb_context->dest_sv;
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
memcached_mget_by_key(Memcached__libmemcached ptr, lmc_key master_key, size_t length(master_key), SV *keys_rv)
    PREINIT:
        char **keys;
        size_t *key_length;
        unsigned int number_of_keys;
    CODE:
        if ((RETVAL = _prep_keys_lengths(ptr, keys_rv, &keys, &key_length, &number_of_keys)) == MEMCACHED_SUCCESS) {
            RETVAL = memcached_mget_by_key(ptr, master_key, XSauto_length_of_master_key, keys, key_length, number_of_keys);
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
        if ((RETVAL = _prep_keys_lengths(ptr, keys_ref, &keys, &key_length, &number_of_keys)) == MEMCACHED_SUCCESS) {
            RETVAL = memcached_mget(ptr, keys, key_length, number_of_keys);
            Safefree(keys);
            Safefree(key_length);
            RETVAL = _fetch_all_hashref(ptr, RETVAL, dest_ref);
        }
    OUTPUT:
        RETVAL



lmc_value
memcached_fetch(Memcached__libmemcached ptr, \
        OUT lmc_key key, \
        IN_OUT lmc_data_flags_t flags=0, \
        IN_OUT memcached_return error=0)
    PREINIT:
        size_t key_length=0;
        size_t value_length=0;
        char key_buffer[MEMCACHED_MAX_KEY];
    INIT: 
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
memcached_delete(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        lmc_expiration expiration= 0)

memcached_return
memcached_delete_by_key (Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        lmc_expiration expiration= 0)



=head2 Functions for Accessing Statistics from memcached

=cut


=head2 Miscellaneous Functions

=cut

memcached_return
memcached_verbosity(Memcached__libmemcached ptr, unsigned int verbosity)

memcached_return
memcached_flush(Memcached__libmemcached ptr, lmc_expiration expiration=0)

void
memcached_quit(Memcached__libmemcached ptr)

char *
memcached_strerror(Memcached__libmemcached ptr, memcached_return rc)

SV *
memcached_errstr(Memcached__libmemcached ptr)
    PREINIT:
        lmc_state_st* lmc_state;
    CODE:
        RETVAL = newSV(0);
        lmc_state = LMC_STATE(ptr);
        /* setup return value as a dualvar with int err code and string error message */
        sv_setiv(RETVAL, lmc_state->last_return);
        sv_setpv(RETVAL, memcached_strerror(ptr, lmc_state->last_return));
        if (lmc_state->last_return == MEMCACHED_ERRNO) {
            sv_catpvf(RETVAL, " %s", strerror(lmc_state->last_errno));
        }
        SvIOK_on(RETVAL); /* set as dualvar */
    OUTPUT:
        RETVAL

const char *
memcached_lib_version() 

=pod not in 0.14
memcached_return
memcached_version(Memcached__libmemcached ptr)
=cut

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

void
memcached_set_callback_coderefs(Memcached__libmemcached ptr, SV *set_cb, SV *get_cb)
    PREINIT:
        lmc_state_st *lmc_state;
    CODE:
        if (SvOK(set_cb) && !(SvROK(set_cb) && SvTYPE(SvRV(set_cb)) == SVt_PVCV))
            croak("set_cb is not a reference to a subroutine");
        if (SvOK(get_cb) && !(SvROK(get_cb) && SvTYPE(SvRV(get_cb)) == SVt_PVCV))
            croak("get_cb is not a reference to a subroutine");
        lmc_state = LMC_STATE(ptr);
        sv_setsv(lmc_state->cb_context->set_cb, set_cb);
        sv_setsv(lmc_state->cb_context->get_cb, get_cb);
