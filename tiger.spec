# Build relocatable? (1=yes 0=no)
%define want_reloc 1
%{?build_want_reloc:%define want_reloc 1}

# Is this the distributable or local test version? (1=distr 0=test)
%define want_distr 1
%{?build_want_distr:%define want_distr 1}

# Do we want to keep non-Linux systems
%define keep_other_sys 0 
%{?build_want_distr:%define keep_other_sys 0}

%define maj 3
%define min 2
%define rev 1
%define cvs 2003.08.19.00.00.00

Summary: Security auditing on UNIX systems
Name: tiger
Version: %{maj}.%{min}
%if %{want_distr}
Release: %{rev}
%else
Release: %{rev}.%{cvs}
%endif
License: GPL
Group: System Environment/Base
URL: http://www.tigersecurity.org
Source: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}
Provides: %{name}
%if %{want_reloc}
Prefix: /usr/sbin
Prefix: /usr/lib
Prefix: /var
Prefix: /etc
%else
Prefix: /usr/local
%endif



%description
TIGER, or the 'tiger' scripts, is a set of Bourne shell scripts,
C programs and data files which are used to perform a security audit
of UNIX systems.  It is designed to hopefully be easy to use, easy to
understand and easy to enhance.  Currently support for SunOS 4.x and
SunOS 5.x is the best, followed by NeXT 3.x.  Other systems for which
(at least partial) configuration files are provided are IRIX 4.x, AIX
3.x, UNICOS 6.x, Linux 0.99.x and HP/UX.  These configurations are not
tested as thoroughly as the SunOS and NeXT configurations, and in some
cases, may barely work.  For other systems, a "best effort" check will
be performed.
This is TIGER release %{version}.%{release}


%prep
%setup -q

%build
autoconf
./configure \
	--prefix=${RPM_BUILD_ROOT} \
	--mandir=/usr/share/man \
%if %{want_reloc}
	--with-tigerhome=/usr/lib/tiger \
	--with-tigerbin=/usr/sbin \
	--with-tigerconfig=/etc/tiger \
	--with-tigerwork=/var/run/tiger \
	--with-tigerlog=/var/log/tiger
%else
	--with-tigerhome=/usr/local/tiger \
	--with-tigerbin=/usr/local/tiger/bin \
	--with-tigerconfig=/usr/local/tiger/etc \
	--with-tigerwork=/usr/local/tiger/run \
	--with-tigerlog=/usr/local/tiger/log
%endif

if grep /proc/version -qe " SMP "; then opt='-j 3'; fi
make ${opt}


%install
export DESTDIR=${RPM_BUILD_ROOT}
# Generic call 
make install
# OS Specific 
# 1.- Cron job installation
mkdir -p ${DESTDIR}/etc/cron.d/
chmod 755 ${DESTDIR}/etc/cron.d/
%if  %{want_reloc}
install -m644 debian/cron.d ${DESTDIR}/etc/cron.d/tiger
%else
sed -es 's/usr\/sbin/usr\/local\/tiger\/bin/g' < debian/cron.d >${DESTDIR}/etc/cron.d/tiger
chmod 644 ${DESTDIR}/etc/cron.d/tiger
%endif
# 2.- Tiger.ignore (needs to be revised for RedHat)
%if %{want_reloc}
install -m600 debian/debian.ignore ${DESTDIR}/etc/tiger/tiger.ignore
%else
install -m600 debian/debian.ignore ${DESTDIR}/usr/local/etc/tiger.ignore
%endif
# 3.- This should be done by the Makefile, grumble...
%if %{want_reloc}
install -m 644 version.h ${DESTDIR}/usr/lib/tiger/
%else
install -m 644 version.h ${DESTDIR}/usr/local/tiger/
%endif
# Removed unnecesary stuff 
%if ! %{keep_other_sys}
for system in AIX HPUX IRIX NeXT SunOS UNICOS UNICOSMK Tru64 MacOSX ; 
do
%if %{want_reloc}
rm -rf ${RPM_BUILD_ROOT}/usr/lib/tiger/systems/${system}; 
%else 
rm -rf ${RPM_BUILD_ROOT)/usr/local/tiger/systems/${system}; 
%endif
done
%endif
find ${RPM_BUILD_ROOT} -type d -name CVS | xargs -iX rm -rf "X"


%clean
rm -rf ${RPM_BUILD_ROOT}


%post
# Nothing necessary here


%preun
# Nothing necessary here


%postun
# Nothing necessary here


%files
%defattr(-,root,root)
# Common directories regardless of if its relocated or not
/etc/cron.d
/usr/share/man
# Directories that will change if relocated
%if %{want_reloc}
/usr/sbin/
/usr/lib/%{name}
/var/run/%{name}
/var/log/%{name}
/etc/%{name}
%else
/usr/local/%{name}
%endif

%changelog
* Sun Jan 25 2004 Ryan Bradietch <rbradetich@uswest.net>
- Changed permissions on ${DESTDIR}/etc/cron.d from: 766 to 755.
- Added a call to autoconf in the %build section.

* Sat Dec 27 2003 Javier Fernandez-Sanguino <jfs@debian.org>
- Spec file when relocatable now uses /usr/lib instead of /usr/local/tiger
- Fixed grep of /proc/version so that build does not stop in RH 7.3
  (it builds fine in Debian sid though :-)
- Cron file is now installed in /etc/cron.d/tiger
- Version.h file is now installed (should be done by the Makefile)
- Install ignore file (but needs to be revised)
- Always remove the systems we don not care for (just leave Linux)
- Remove the systems we don not care for (just leave Linux) based on
  the keep_other_sys variable
- Added /usr/sbin (if relocatable) and /etc/cron.d/ in the generic case
  to the distributed files.
- Changed /var/log to /var/log/tiger
- NOTE: I don't expect the relocatable part to work properly (since Tiger
  has been already 'configured'). I'll leave it momentarily until
  I decide what to do with it. If it's relocated Tiger will _NOT_ work
  (until the hardcoded paths are changed), this could be done in the
  %post installation properly, though.

* Wed Sep 24 2003 unSpawn <unSpawn@rootshell.be> XIII
- Made spec file build relocatable and reflect tru parameterisation
- Strip CVS dirs on build
- Strip AIX, HPUX, Sun and Mac systems dir on build (should be defines)

* Sun May 4 2003 unSpawn <unSpawn@rootshell.be> 3.2rc3-2003.23.04.13.00
- First attempt to build from sources "made easy" by Javier incorporating
  a default Makefile script.


