%define maj 3
%define min 2 
%define rev 1
%define rel 2003.08.19.00.00.00

Summary: Security auditing on UNIX systems
Name: tiger
Version: %{maj}.%{min}
Release: %{rel}
License: GPL
Group: System Environment/Base
Source: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}
Provides: %{name}



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

Note[0]: This package currently installs in /usr/local/tiger.
Note[1]: Please adjust your /usr/local/tiger/tigerrc before running.

%prep
%setup -q

%build
./configure \
	--prefix=${RPM_BUILD_ROOT} \
	--with-tigerhome=/usr/local/tiger \
	--with-tigerconfig=/usr/local/tiger \
	--with-tigerwork=/usr/local/tiger/run \
	--with-tigerlog=/var/log \
	--with-tigerbin=/usr/local/tiger/bin
# Hurry up
grep /proc/version -qe " SMP "; case "$?" in 0) opt='-j 3';; esac
make ${opt}

%install
export DESTDIR=${RPM_BUILD_ROOT}
make install


%clean
rm -rf ${RPM_BUILD_ROOT}

%post
printf "%sPlease adjust your /usr/local/tiger/tigerrc before running.\n"


%preun
# Nothing necessary here


%postun
# Nothing necessary here


%files
%defattr(-,root,root)
/usr/local/%{name}



%changelog
* Sun May 4 2003 unSpawn <unSpawn@rootshell.be> 3.2rc3-2003.23.04.13.00
- First attempt to build from sources "made easy" by Javier incorporating
  a default Makefile script.


