use strict;
use warnings;

use ExtUtils::MakeMaker;
use Cwd qw(abs_path);

my $lmcd_src = "src/libmemcached";
my $lmcd_inst = abs_path("src_inst");

my ($lmcd_h) = eval { build_libmemcached() };
if ($@) {
    warn "Unable to build libmemcached: $@\n";
    warn "Aborted.\n";
    exit 0; # tell cpan testers that this is not a failure
}

WriteMakefile(
    NAME                => 'Memcached::libmemcached',
    AUTHOR              => 'Tim Bunce <Tim.Bunce@pobox.com>',
    VERSION_FROM        => 'libmemcached.pm',
    ABSTRACT_FROM       => 'libmemcached.pm',
    INC                 => "-I$lmcd_inst",
    LIBS                => "-L$lmcd_inst/lib -lmemcached",
    PREREQ_PM           => {
        'Test::More' => 0,
    },
    dist                => {
        COMPRESS => 'gzip -9f', SUFFIX => 'gz',
    },
    clean               => {
        FILES => 'Memcached-libmemcached-*',
    },
);


sub MY::postamble {
return qq{
LMCD_SRC=$lmcd_src
LMCD_INST=$lmcd_inst
}.q{
clean ::
	$(RM_RF) $(LMCD_INST)

realclean ::
	cd $(LMCD_SRC) && $(MAKE) distclean
    }
}



exit 0;


sub run {
    my ($cmd) = @_;
    warn "$cmd\n";
    system($cmd) == 0
        or die "Error running $cmd\n";
}

sub build_libmemcached {
    return if -d "$lmcd_inst/lib"; # XXX assume it built ok. use 'make realclean' to rm
    mkdir $lmcd_inst unless -d $lmcd_inst;
    run("cd $lmcd_src && make distclean") if -f "$lmcd_src/Makefile";
    run("cd $lmcd_src && ./configure --prefix=$lmcd_inst");
    run("cd $lmcd_src && CFLAGS=-g LDFLAGS=-g make install");
    sync_libmemcached_pod();
}

sub sync_libmemcached_pod {
    return unless -d ".svn";
    # we duplicate the libmemcached pod in svn so that the docs can be read on search.cpan.org
    my $perl_pod_dir = "lib/Memcached/libmemcached";
    my @src_pod = <$lmcd_src/docs/memcached_*.pod>;
    for my $src_pod (@src_pod) {
        (my $dst_pod = $src_pod) =~ s!$lmcd_src/docs!$perl_pod_dir!;
        run("cp $src_pod $dst_pod && svn add -q $dst_pod");
    }
    # XXX svn rm any $perl_pod_dir/memcached_*.pod that weren't in @src_pod
}

