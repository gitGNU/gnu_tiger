# Generated automatically from Makefile.in by configure.
#
#  You only need to 'make' tiger if you are planning to run it
#  on a regular basis, or to compile the binaries (sources under c/)
#  for your platform (these binaries might be needed by some checks)
#
#------------------------------------------------------------------------
#
# This directory will contain the 'tiger', 'tigercron', 'tigexp'
# scripts, config files, the 'scripts' subdirectory which will
# contain the checking scripts, the platform specific scripts, etc.
# None of this will need to be writable once installed.
#
TIGERHOME=.
#
# This directory is used for scratch files while the scripts
# are running.  It can be /tmp.  By using something other
# than /tmp (something used only by the 'tiger' scripts), you
# can easily clean up the occasional dribbles left by 'tiger'
# (report these... don't want anything left laying around).
# 
# Of course, it is necessary that this directory be writable.
#
TIGERWORK=run/
#
# Where do log files go.  This directory must be writable.
#
TIGERLOGS=log/
#
# Where do binary executables go... this is only used if the
# binary executables don't exist in the appropriate platform
# sub-directory under $(TIGERHOME)/systems
#
TIGERBIN=.
#
# Which is the prefix of where the system is going to be installed.
# 
prefix=/usr/local/tiger
#
#------------------------------------------------------------------------
#
# End of user customization...
#
#------------------------------------------------------------------------
#

PLATFORM_SCRIPTS:=$(shell find ./systems/ -type f)

BINARIES=./tiger \
	 ./tigexp  \
	 ./tigercron \
SCRIPTS=./scripts/check_accounts \
	./scripts/check_aliases \
	./scripts/check_anonftp \
	./scripts/check_cron \
	./scripts/check_devices \
	./scripts/check_embedded \
	./scripts/check_exports \
	./scripts/check_group \
	./scripts/check_inetd \
	./scripts/check_issue \
	./scripts/check_known \
	./scripts/check_logfiles \
	./scripts/check_netrc \
	./scripts/check_network \
	./scripts/check_nisplus \
	./scripts/check_passwd \
	./scripts/check_path \
	./scripts/check_perms \
	./scripts/check_printcap \
	./scripts/check_rhosts \
	./scripts/check_root \
	./scripts/check_rootdir \
	./scripts/check_sendmail \
	./scripts/check_signatures \
	./scripts/check_system \
	./scripts/check_listeningprocs \
	./scripts/check_ftpusers \
	./scripts/check_tcpd \
	./scripts/crack_run \
	./scripts/tripwire_run \
	./scripts/find_files \
	./util/buildbins \
	$(PLATFORM_SCRIPTS)


MISCFILES=./initdefs \
	./check.tbl \
	./syslist \
	./tigerrc \
	./cronrc \
	./util/difflogs \
	./util/flogit \
	./util/genmsgidx \
	./util/getfs-amd \
	./util/getfs-automount \
	./util/getfs-nfs \
	./util/getfs-std \
	./util/gethostinfo \
	./util/getnetgroup \
	./util/logit \
	./util/setsh \
	./util/sgrep

MISCDIRS=./bin \
	./doc \
	./html \
	./man \
	./scripts/sub \
	./systems

all:
	cd c && $(MAKE) all
	cd util && sh doc2html
	./util/genmsgidx

install: 
	cd c && $(MAKE) install
	if [ ! -d $(prefix)/$(TIGERHOME) ]; then \
	  mkdir -p $(prefix)/$(TIGERHOME); \
	  chmod 755 $(prefix)/$(TIGERHOME); \
        fi; \
	if [ ! -d $(prefix)/$(TIGERWORK) ]; then \
	  mkdir -p $(prefix)/$(TIGERWORK); \
	  chmod 700 $(prefix)/$(TIGERWORK); \
	fi; \
	if [ ! -d $(prefix)/$(TIGERLOGS) ]; then \
	  mkdir -p $(prefix)/$(TIGERLOGS); \
	  chmod 700 $(prefix)/$(TIGERLOGS); \
	fi; \
	if [ ! -d $(prefix)/$(TIGERHOME)/scripts ]; then \
	  mkdir $(prefix)/$(TIGERHOME)/scripts; \
	  chmod 755 $(prefix)/$(TIGERHOME)/scripts; \
	fi; \
	if [ ! -d $(prefix)/$(TIGERHOME)/util ]; then \
	  mkdir $(prefix)/$(TIGERHOME)/util; \
	  chmod 755 $(prefix)/$(TIGERHOME)/util; \
	fi; \
	if [ ! -d $(prefix)/$(TIGERBIN) ]; then \
	  mkdir $(prefix)/$(TIGERBIN); \
	  chmod 755 $(prefix)/$(TIGERBIN); \
	fi; \
        for dir in $(MISCDIRS); do \
	  tar cf - $$dir | (cd $(prefix)/$(TIGERHOME); tar xpf -); \
	done; \
	for file in $(MISCFILES); do \
	  cp -p $$file $(prefix)/$(TIGERHOME)/$$file; \
	done; \
	for file in $(BINARIES); do \
	  cp -p $$file $(prefix)/$(TIGERBIN)/$$file; \
	  chmod 755 $(prefix)/$(TIGERBIN)/$$file ; \
	done; \
	for file in $(SCRIPTS); do \
	  sed -e 's%^TigerInstallDir=.*$$%TigerInstallDir="'$(TIGERHOME)'"%' \
	      $$file > $(prefix)/$(TIGERHOME)/$$file;\
	  chmod 755 $(prefix)/$(TIGERHOME)/$$file; \
	done; \
#	sed -e 's%^TigerLogDir=.*$$%TigerLogDir="'$(TIGERLOGS)'"%' \
#	    -e 's%^TigerWorkDir=.*$$%TigerWorkDir="'$(TIGERWORK)'"%' \
#	    -e 's%^TigerBinDir=.*$$%TigerBinDir="'$(TIGERBIN)'"%' \
#	    ./config > $(prefix)/$(TIGERHOME)/config; \
	chmod 644 $(prefix)/$(TIGERHOME)/config;
	(cd $(prefix)/$(TIGERHOME); ./util/genmsgidx doc/*.txt)

clean: 
	cd c && $(MAKE) clean
	-find bin/ -type f -exec rm -f {} \;
	-rm -f man/index.bt config.{status,log,cache}

distclean: clean
	cd c && $(MAKE) distclean 
	-find log/ -type f -exec rm -f {} \;
	-find run/ -type f -exec rm -f {} \;
	-rm -f Makefile 

maintainerclean: distclean
	-rm -f configure tiger config tigercron

configure: configure.in
	autoconf

# Configure the package with the defaults (will install to /usr/local/)
config: configure
	./configure
	chmod 755 tiger tigercron config tigexp

# Configure the package to run in the local dir
config-local: configure
	./configure --with-tigerhome=. --with-tigerconfig=. \
		--with-tigerwork=run/ --with-tigerlog=log/ --with-tigerbin=. \
		--prefix=/usr/local/tiger
	chmod 755 tiger tigercron config tigexp
