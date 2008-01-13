# tests for functions documented in memcached_create.pod

# XXX memcached_clone needs more testing for non-undef args

use Test::More tests => 5;

BEGIN { use_ok( 'Memcached::libmemcached' ) }

$Exporter::Verbose = 1;

ok !defined &memcached_create, 'should not import func by default';
Memcached::libmemcached->import( 'memcached_create' );
ok  defined &memcached_create, 'should import func on demand';

ok !defined &MEMCACHED_SUCCESS, 'should not import MEMCACHED_SUCCESS by default';
ok !defined &MEMCACHED_FAILURE, 'should not import MEMCACHED_FAILURE by default';
Memcached::libmemcached->import( 'MEMCACHED_SUCCESS' );
ok  defined &MEMCACHED_SUCCESS, 'should import MEMCACHED_SUCCESS on demand';
ok !defined &MEMCACHED_FAILURE, 'should not import MEMCACHED_FAILURE when importing MEMCACHED_SUCCESSi';

ok !defined &MEMCACHED_HASH_MD5, 'should not import MEMCACHED_HASH_MD5 by default';
ok !defined &MEMCACHED_HASH_CRC, 'should not import MEMCACHED_HASH_CRC by default';
Memcached::libmemcached->import( ':memcached_hash' );
ok  defined &MEMCACHED_HASH_MD5, 'should import MEMCACHED_HASH_MD5 by :memcached_hash tag';
ok  defined &MEMCACHED_HASH_CRC, 'should import MEMCACHED_HASH_CRC by :memcached_hash tag';

ok 1;
