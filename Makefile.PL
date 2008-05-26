use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;

use Getopt::Long;
use Data::Dumper;
use Cwd qw(getcwd abs_path);

BEGIN {
    my $min = 5.006;
    if ($] < $min) {
        warn "Perl version $] is below minimum $min required. Upgrade!\n";
        exit 0;
    }
}


GetOptions(
    'g!'    => \my $opt_g,      # enable debugging
    'pg!'   => \my $opt_pg,     # enable profiling
    'cov!'  => \my $opt_cov,    # enable test coverage analysis
    'bin!'  => \my $opt_bin,    # install bintools from libmemcached
) or exit 1;

my $lmcd_src = "src/libmemcached";
my $lmcd_inst = getcwd()."/src_inst";
my $lmcd_built_lib = "$lmcd_inst/lib/libmemcached$Config{lib_ext}";
my @lmcd_pod = sort <$lmcd_src/docs/memcached_*.pod>;
my $is_developer = (-d ".svn");

my ($lmcd_h) = eval { build_libmemcached() };
if ($@) {
    warn "Unable to build libmemcached: $@\n";
    warn "Aborted.\n";
    exit 0; # tell cpan testers that this is not a failure
}

my %opts;
if (my $gccversion = $Config{gccversion}) {     # ask gcc to be more pedantic
    print "Your perl was compiled with gcc (version $Config{gccversion}), okay.\n";
    $gccversion =~ s/[^\d\.]//g; # just a number please
    $opts{DEFINE} .= ' -W -Wall -Wpointer-arith -Wbad-function-cast';
    $opts{DEFINE} .= ' -Wno-comment -Wno-sign-compare -Wno-cast-qual';
    $opts{DEFINE} .= ' -Wmissing-noreturn -Wno-unused-parameter' if $gccversion ge "3.0";
    if ($is_developer) {
        #$opts{DEFINE} .= ' -DPERL_GCC_PEDANTIC -ansi -pedantic' if $gccversion ge "3.0";
        $opts{DEFINE} .= ' -Wdisabled-optimization -Wformat'    if $gccversion ge "3.0";
        $opts{DEFINE} .= ' -Wmissing-prototypes';
    }
}
$opts{OPTIMIZE} = "-g"  if $opt_g;
$opts{CCFLAGS}  = "-pg" if $opt_pg;
my $coverage_flags = "";
if ($opt_cov) {
    $opts{OPTIMIZE} = "-O0";
    # http://search.cpan.org/~pjcj/Devel-Cover/gcov2perl
    $coverage_flags = "-fprofile-arcs -ftest-coverage";
    $opts{CCFLAGS}  = $coverage_flags;
}

### optionally install the command line utilities that come with
### libmemcached as well
if( $opt_bin ) {
    $opts{EXE_FILES} = [ map { s/\.c$//i; $_ } <src/libmemcached/clients/mem*.c> ]; 
}

WriteMakefile(
    NAME                => 'Memcached::libmemcached',
    AUTHOR              => 'Tim Bunce <Tim.Bunce@pobox.com>',
    VERSION_FROM        => 'libmemcached.pm',
    ABSTRACT_FROM       => 'libmemcached.pm',
    INC                 => "-I$lmcd_inst/include",
    # We want to link to *our* private libmemcached and not one that
    # might already be installed on the system. The LIBS config gets
    # appended to the link command line, so if we used "-L$dir -lmemcached"
    # then the installed lib would get preference over ours.
    # So we explicitly refer to our static library. That also avoids the
    # need to worry about what library might get used at runtime.
    LDFROM           => '$(OBJECT)'." $lmcd_built_lib",
    PREREQ_PM           => {
        'Test::More' => 0,
    },
    dynamic_lib         => {
        OTHERLDFLAGS => ($opt_pg ? "-pg " : "")
                      . ($opt_g  ? "-g "  : "") 
                      . $coverage_flags,
    },
    dist                => {
        COMPRESS => 'gzip -9f', SUFFIX => 'gz',
        DIST_DEFAULT=> 'clean distcheck disttest tardist',
        PREOP => '$(MAKE) -f Makefile.old distdir',
    },
    # see also MY::postamble below
    clean               => {
        FILES => 'Memcached-libmemcached-* lib/Memcached/libmemcached/*_hash.pl *.gcov libmemcached.gcda libmemcached.gcno',
    },
    %opts,
);


{   package MY;

sub postamble {
return qq{
COVER = cover
LMCD_SRC=$lmcd_src
LMCD_INST=$lmcd_inst
LMCD_BUILT_LIB=$lmcd_built_lib
}.q{
coverclean:
	$(COVER) -delete

testcover: coverclean pure_all
	HARNESS_PERL_SWITCHES='-MDevel::Cover=-coverage,branch,-coverage,condition,-coverage,pod,-coverage,statement,-coverage,subroutine' PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE), '$(INST_LIB)','$(INST_ARCHLIB)')" $(TEST_FILES)
	gcov libmemcached.xs
	gcov2perl *.gcov
	$(COVER) 

clean ::

realclean ::
	$(RM_RF) $(LMCD_INST)
	cd $(LMCD_SRC) && $(MAKE) distclean


libmemcached.c : $(XSUBPPDIR)/ParseXS.pm typemap

$(OBJECT) : $(LMCD_BUILT_LIB)

svnmanifest::
	svn list -R .@HEAD | sort | grep -v '/$$' > MANIFEST
	svn diff MANIFEST
	svn status

checkkeywords:
	$(RM_RF) blib
	find . -type f \( -name .svn -prune -o -name \*.pm -o -name \*.PL -o -name \*.pl \) \
	    -exec bash -c '[ -z "$$(svn pg svn:keywords {})" ] && echo svn propset svn:keywords \"Id Revision\" {}' \;

checkpod:
	$(RM_RF) blib
	find . -type f \( -name .svn -prune -o -name \*.pm -o -name \*.PL -o -name \*.pl \) \
	    -exec podchecker {} \; 2>&1 | grep -v 'pod syntax OK'

}
}


sub tool_xsubpp {
    #my $string = shift->SUPER::tool_xsubpp(@_);
    # Prepend -It/lib to XSUBPP (we do this instead of editing XSUBPPRUN because
    # XSUBPPRUN didn't exist in perl 5.6)
    return q{
XSUBPPDIR=t/lib/ExtUtils
XSUBPP = -It/lib $(XSUBPPDIR)/xsubpp
XSUBPPRUN = $(PERLRUN) $(XSUBPP)
};
}

} # end of package MY

exit 0;


sub run {
    my ($cmd) = @_;
    warn "$cmd\n";
    system($cmd) == 0
        or die "Error running $cmd\n";
}

sub build_libmemcached {
    sync_libmemcached_pod();
    extract_libmemcached_functions();
    extract_libmemcached_constants();

    return if -d "$lmcd_inst/lib"; # XXX assume it built ok. use 'make realclean' to rm
    mkdir $lmcd_inst, 0775 unless -d $lmcd_inst;
    run("cd $lmcd_src && make distclean") if -f "$lmcd_src/Makefile";
    my $configure_args = '--with-pic'; #'--disable-shared';
    $configure_args .= ' --enable-debug' if $opt_g;
    $configure_args .= ' CFLAGS=-pg LDFLAGS=-pg' if $opt_pg;
    if ($is_developer) {    # XXX make a Makefile.PL argument/option
    }
    run("cd $lmcd_src && ./configure --prefix=$lmcd_inst $configure_args");
    #run("cd $lmcd_src && make test") if $is_developer; # XXX
    run("cd $lmcd_src && make install");
}

sub sync_libmemcached_pod {
    return unless -d ".svn";
    # we duplicate the libmemcached pod in svn so that the docs can be read on search.cpan.org
    my $perl_pod_dir = "lib/Memcached/libmemcached";
    for my $src_pod (@lmcd_pod) {
        (my $dst_pod = $src_pod) =~ s!$lmcd_src/docs!$perl_pod_dir!;
        $dst_pod =~ s/\.pod/\.pm/;
        open my $src, "<$src_pod" or die "Can't open $src_pod: $!";
        open my $dst, ">$dst_pod" or die "Can't open $dst_pod: $!";

        # convert path into package
        (my $dst_pkg = $dst_pod) =~ s{/}{::}g;
        $dst_pkg =~ s{ lib:: (.*?) \.\w+ $ }{$1}x;

        print $dst "package $dst_pkg;\n\n"; # for search.cpan.org
        while (<$src>) {
            print $dst $_;
        }
        print $dst "1;\n";
        close $dst or die "Error closing $dst_pod: $!";
        run("svn add -q $dst_pod");
    }
    # XXX svn rm any $perl_pod_dir/memcached_*.pod that weren't in @lmcd_pod
}

sub extract_libmemcached_functions {
    my %libmemcached_func;

    # find all memcached_* functions
    warn "Reading libmemcached pod docs to find all public functions\n";
    for my $src_pod (@lmcd_pod) {
        open my $fh, "<$src_pod" or die "Can't open $src_pod: $!";
        #warn $src_pod;
        while (<$fh>) {
            next unless /\b(memcached_\w+)\s*\([^3]/;
            $libmemcached_func{$1} = 1
                unless $1 eq 'memcached_return'; # parsing fooled by callback
            #warn "\t$1\t$_";
        }
    }

    # write 
    my $func_pm = "lib/Memcached/libmemcached/func_hash.pl";
    warn "Writing $func_pm\n";
    open my $func_pm_fh, ">$func_pm" or die "Can't open $func_pm: $!";
    local $\ = "\n";
    print $func_pm_fh "# DO NOT EDIT! GENERATED BY $0 ON ".localtime(time)."\n";
    print $func_pm_fh "".Data::Dumper->Dump([\%libmemcached_func], [qw(libmemcached_func)]);
    close $func_pm_fh or die "Error closing $func_pm: $!";

    # sanity check the generated file
    my $loaded = require $func_pm;
    die "$func_pm didn't return a HASH reference ($loaded)"
        unless ref $loaded eq 'HASH';
}

sub extract_libmemcached_constants {
    my %libmemcached_const;

    # find all MEMCACHED_* constants (#define and enum)
    warn "Reading headers to find all constants\n";
    my $in_enum = 0;
    my @const;

    my @headers = glob "$lmcd_src/libmemcached/memcached*.h";
    for my $h (@headers) {
        open my $fh, "<$h" or die "Can't open $h: $!";
        while (<$fh>) {
            if ($in_enum) {
                if (m/^ \s* } \s* (\w+)/x) { # end of enum
                    $libmemcached_const{$_} = $1 for @const;
                    @const = ();
                    $in_enum = 0;
                }
                elsif (m/^ \s* (MEMCACHED_\w+)/x) {
                    push @const, $1;
                }
            }
            elsif (m/^ \s* typedef \s+ enum /x) {
                $in_enum = 1;
            }
            elsif (m/\# \s* define \s+ (MEMCACHED_\w+)/x) {
                $libmemcached_const{$1} = "defines";
            }
        }
    }

    # write raw hash of const names
    my $const_pl = "lib/Memcached/libmemcached/const_hash.pl";
    warn "Writing $const_pl\n";
    open my $const_pl_fh, ">$const_pl" or die "Can't open $const_pl: $!";
    local $\ = "\n";
    print $const_pl_fh "# DO NOT EDIT! GENERATED BY $0 ON ".localtime(time)."\n";
    print $const_pl_fh "".Data::Dumper->Dump([\%libmemcached_const], [qw(libmemcached_const)]);
    close $const_pl_fh or die "Error closing $const_pl: $!";

    # sanity check the generated file
    my $loaded = require $const_pl;
    die "$const_pl didn't return a HASH reference ($loaded)"
        unless ref $loaded eq 'HASH';

    # write raw hash of const names
    my $const_xs = "const-xs.inc";
    warn "Writing $const_xs\n";
    open my $const_xs_fh, ">$const_xs" or die "Can't open $const_xs: $!";
    local $\ = "\n";
    print $const_xs_fh "# DO NOT EDIT! GENERATED BY $0 ON ".localtime(time)."\n";
    print $const_xs_fh "IV\nconstant()";
    print $const_xs_fh "\tALIAS:";
    print $const_xs_fh "\t$_ = $_" for sort keys %libmemcached_const;
    print $const_xs_fh "\tCODE:";
    print $const_xs_fh "\tRETVAL = ix;";
    print $const_xs_fh "\tOUTPUT:";
    print $const_xs_fh "\tRETVAL";
    close $const_xs_fh or die "Error closing $const_xs: $!";

    # now write a pod file to document the constants and tags

    # invert libmemcached_const into hash of tags with arrays of name
    my %libmemcached_tags;
    push @{ $libmemcached_tags{ $libmemcached_const{$_} } }, $_ for keys %libmemcached_const;
    # open file and write prologue
    my $const_pm = "lib/Memcached/libmemcached/constants.pm";
    warn "Writing $const_pm\n";
    open my $const_pm_fh, ">$const_pm" or die "Can't open $const_pm: $!";
    local $\ = "\n";
    print $const_pm_fh "# DO NOT EDIT! GENERATED BY $0 ON ".localtime(time)."\n";
    print $const_pm_fh $_ for (
        "=head1 NAME\n",
        "Memcached::libmemcached::constants - document list of constants defined by libmemcached\n",
        "=head1 DESCRIPTION\n",
        "This file just lists all the constants defined by libmemcached which are available to import via the L</Memcached::libmemcached> module.\n",
        "Each constant can be imported individually by name. "
        ."Groups of related constants, such as the elements of an C<enum> type, "
        ."can be imported as a set using a C<:tag> name. "
        ."See L<Exporter> for more information about tags.\n",
    );
    # write out tags and their constants
    print $const_pm_fh "=head1 TAGS\n";
    for my $tag (sort keys %libmemcached_tags) {
        my $names = $libmemcached_tags{$tag} or die "panic";
        print $const_pm_fh "=head2 :$tag\n";
        print $const_pm_fh "  $_"
            for sort @$names;
        print $const_pm_fh "";
    }
    # close up
    print $const_pm_fh "=cut\n\n1;\n";
    close $const_pm_fh or die "Error closing $const_pm: $!";
    run("svn add -q $const_pm") if $is_developer;
}

