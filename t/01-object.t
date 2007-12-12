
use Test::More tests => 10;

BEGIN {
use_ok( 'Memcached::libmemcached' );
}

my $obj;

ok( $obj = Memcached::libmemcached->new(), "no initializer");
isa_ok($obj,"Memcached::libmemcached");

ok( $obj = Memcached::libmemcached->new(1), "initial numeric value");
ok($obj->{value} == 1, "implicit initializer");

ok( $obj = Memcached::libmemcached->new("fish"), "initial string value");
ok($obj->{value} eq "fish", "implicit initializer");

ok( $obj = Memcached::libmemcached->new(color => "red", flavor => "sour"), 
	"hash as initializer");
ok( $obj->{color} eq "red", "first hash key");
ok( $obj->{flavor} eq "sour", "first hash key");
