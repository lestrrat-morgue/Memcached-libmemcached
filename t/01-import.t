# tests for functions documented in memcached_create.pod

# XXX memcached_clone needs more testing for non-undef args

use Carp;
use Test::More tests => 15;

BEGIN { use_ok( 'Memcached::libmemcached' ) }

#$Exporter::Verbose = 1;

ok !defined &memcached_create, 'should not import func by default';
Memcached::libmemcached->import( 'memcached_create' );
ok  defined &memcached_create, 'should import func on demand';

# we use exists not defined for constants because they're handled by AUTOLOAD

ok !exists &MEMCACHED_SUCCESS, 'should not import MEMCACHED_SUCCESS by default';
ok !exists &MEMCACHED_FAILURE, 'should not import MEMCACHED_FAILURE by default';
Memcached::libmemcached->import( 'MEMCACHED_SUCCESS' );
ok  exists(&MEMCACHED_SUCCESS), 'should import MEMCACHED_SUCCESS on demand';
ok !exists &MEMCACHED_FAILURE, 'should not import MEMCACHED_FAILURE when importing MEMCACHED_SUCCESSi';

ok defined MEMCACHED_SUCCESS;

ok !exists &MEMCACHED_HASH_MD5, 'should not import MEMCACHED_HASH_MD5 by default';
ok !exists &MEMCACHED_HASH_CRC, 'should not import MEMCACHED_HASH_CRC by default';
Memcached::libmemcached->import( ':memcached_hash' );
ok  exists &MEMCACHED_HASH_MD5, 'should import MEMCACHED_HASH_MD5 by :memcached_hash tag';
ok  exists &MEMCACHED_HASH_CRC, 'should import MEMCACHED_HASH_CRC by :memcached_hash tag';

ok defined MEMCACHED_HASH_MD5;
ok defined MEMCACHED_HASH_CRC;

ok 1;

__END__

t/01-import.......ok 5/5Importing into main from Memcached::libmemcached: MEMCACHED_SUCCESS at t/01-import.t line 17

#   Failed test 'should import MEMCACHED_SUCCESS on demand'
#   in t/01-import.t at line 18.
t/01-import.......ok 9/5Import add: MEMCACHED_HASH_FNV1A_64 MEMCACHED_HASH_FNV1A_32 MEMCACHED_HASH_FNV1_64 MEMCACHED_HASH_KETAMA MEMCACHED_HASH_HSIEH MEMCACHED_HASH_FNV1_32 MEMCACHED_HASH_CRC MEMCACHED_HASH_DEFAULT MEMCACHED_HASH_MD5  at t/01-import.t line 23
Importing into main from Memcached::libmemcached: MEMCACHED_HASH_CRC, MEMCACHED_HASH_DEFAULT, MEMCACHED_HASH_FNV1A_32, MEMCACHED_HASH_FNV1A_64, MEMCACHED_HASH_FNV1_32, MEMCACHED_HASH_FNV1_64, MEMCACHED_HASH_HSIEH, MEMCACHED_HASH_KETAMA, MEMCACHED_HASH_MD5 at t/01-import.t line 23

#   Failed test 'should import MEMCACHED_HASH_MD5 by :memcached_hash tag'
#   in t/01-import.t at line 24.
t/01-import.......NOK 10                                                     
#   Failed test 'should import MEMCACHED_HASH_CRC by :memcached_hash tag'
#   in t/01-import.t at line 25.
t/01-import.......ok 12/5# Looks like you planned 5 tests but ran 7 extra.   
# Looks like you failed 3 tests of 12 run.
t/01-import.......dubious                                                    
        Test returned status 3 (wstat 768, 0x300)

