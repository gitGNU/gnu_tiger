# Build relocatable? (1=yes 0=no)
%define want_reloc 1
%{?build_want_reloc:%define want_reloc 1}

# Is this the distributable or local test version? (1=distr 0=test)
%define want_distr 1
%{?build_want_distr:%define want_distr 1}

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
Source: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}
Provides: %{name}
%if %{want_reloc}
Prefix: /usr/local
Prefix: /var
Prefix: /etc
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
./configure \
	--prefix=${RPM_BUILD_ROOT} \
	--with-tigerhome=/usr/local/tiger \
	--with-tigerbin=/usr/local/tiger/bin \
%if %{want_reloc}
	--with-tigerconfig=/etc/tiger \
	--with-tigerwork=/var/run/tiger \
	--with-tigerlog=/var/log
%else
	--with-tigerconfig=/usr/local/tiger/etc \
	--with-tigerwork=/usr/local/tiger/run \
	--with-tigerlog=/usr/local/tiger/log
%endif

grep /proc/version -qe " SMP "; case "$?" in 0) opt='-j 3';; esac
make ${opt}


%install
export DESTDIR=${RPM_BUILD_ROOT}
make install
%if ! %{want_distr}
find ${RPM_BUILD_ROOT}/usr/local/tiger/systems -maxdepth 1 -type d -a -name \*IX -o -name \*UX -o -name \*SX -o -name \*XT -o -name \*OS -o -name \*64 -o -name UNI\* | xargs -iX rm -rf "X"
find ${RPM_BUILD_ROOT} -type d -name CVS | xargs -iX rm -rf "X"
%endif


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
%if %{want_reloc}
/usr/local/%{name}
/var/run/%{name}
/etc/%{name}
%else
/usr/local/%{name}
%endif

%changelog
* Wed Sep 24 2003 unSpawn <unSpawn@rootshell.be> XIII
- Made spec file build relocatable and reflect tru parameterisation
- Strip CVS dirs on build
- Strip AIX, HPUX, Sun and Mac systems dir on build (should be defines)

* Sun May 4 2003 unSpawn <unSpawn@rootshell.be> 3.2rc3-2003.23.04.13.00
- First attempt to build from sources "made easy" by Javier incorporating
  a default Makefile script.


