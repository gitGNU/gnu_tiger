##
##  install -- Install a program, script or datafile
##  Copyright (c) 1997-2004 Ralf S. Engelschall <rse@engelschall.com>
##
##  This file is part of shtool and free software; you can redistribute
##  it and/or modify it under the terms of the GNU General Public
##  License as published by the Free Software Foundation; either version
##  2 of the License, or (at your option) any later version.
##
##  This file is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##  General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
##  USA, or contact Ralf S. Engelschall <rse@engelschall.com>.
##

str_tool="install"
str_usage="[-v|--verbose] [-t|--trace] [-d|--mkdir] [-c|--copy] [-C|--compare-copy] [-s|--strip] [-m|--mode <mode>] [-o|--owner <owner>] [-g|--group <group>] [-e|--exec <sed-cmd>] <file> [<file> ...] <path>"
arg_spec="1+"
opt_spec="v.t.d.c.C.s.m:o:g:e+"
opt_alias="v:verbose,t:trace,d:mkdir,c:copy,C:compare-copy,s:strip,m:mode,o:owner,g:group,e:exec"
opt_v=no
opt_t=no
opt_d=no
opt_c=no
opt_C=no
opt_s=no
opt_m="0755"
opt_o=""
opt_g=""
opt_e=""

. ./sh.common

#   special case: "shtool install -d <dir> [...]" internally
#   maps to "shtool mkdir -f -p -m 755 <dir> [...]"
if [ "$opt_d" = yes ]; then
    cmd="$0 mkdir -f -p -m 755"
    if [ ".$opt_o" != . ]; then
        cmd="$cmd -o '$opt_o'"
    fi
    if [ ".$opt_g" != . ]; then
        cmd="$cmd -g '$opt_g'"
    fi
    if [ ".$opt_v" = .yes ]; then
        cmd="$cmd -v"
    fi
    if [ ".$opt_t" = .yes ]; then
        cmd="$cmd -t"
    fi
    for dir in "$@"; do
        eval "$cmd $dir" || shtool_exit $?
    done
    shtool_exit 0
fi

#   determine source(s) and destination
argc=$#
srcs=""
while [ $# -gt 1 ]; do
    srcs="$srcs $1"
    shift
done
dstpath="$1"

#   type check for destination
dstisdir=0
if [ -d $dstpath ]; then
    dstpath=`echo "$dstpath" | sed -e 's:/$::'`
    dstisdir=1
fi

#   consistency check for destination
if [ $argc -gt 2 ] && [ $dstisdir = 0 ]; then
    echo "$msgprefix:Error: multiple sources require destination to be directory" 1>&2
    shtool_exit 1
fi

#   iterate over all source(s)
for src in $srcs; do
    dst=$dstpath

    #   if destination is a directory, append the input filename
    if [ $dstisdir = 1 ]; then
        dstfile=`echo "$src" | sed -e 's;.*/\([^/]*\)$;\1;'`
        dst="$dst/$dstfile"
    fi

    #   check for correct arguments
    if [ ".$src" = ".$dst" ]; then
        echo "$msgprefix:Warning: source and destination are the same - skipped" 1>&2
        continue
    fi
    if [ -d "$src" ]; then
        echo "$msgprefix:Warning: source \`$src' is a directory - skipped" 1>&2
        continue
    fi

    #   make a temp file name in the destination directory
    dsttmp=`echo $dst |\
            sed -e 's;[^/]*$;;' -e 's;\(.\)/$;\1;' -e 's;^$;.;' \
                -e "s;\$;/#INST@$$#;"`

    #   verbosity
    if [ ".$opt_v" = .yes ]; then
        echo "$src -> $dst" 1>&2
    fi

    #   copy or move the file name to the temp name
    #   (because we might be not allowed to change the source)
    if [ ".$opt_C" = .yes ]; then
        opt_c=yes
    fi
    if [ ".$opt_c" = .yes ]; then
        if [ ".$opt_t" = .yes ]; then
            echo "cp $src $dsttmp" 1>&2
        fi
        cp $src $dsttmp || shtool_exit $?
    else
        if [ ".$opt_t" = .yes ]; then
            echo "mv $src $dsttmp" 1>&2
        fi
        mv $src $dsttmp || shtool_exit $?
    fi

    #   adjust the target file
    if [ ".$opt_e" != . ]; then
        sed='sed'
        OIFS="$IFS"; IFS="$ASC_NL"; set -- $opt_e; IFS="$OIFS"
        for e
        do
            sed="$sed -e '$e'"
        done
        cp $dsttmp $dsttmp.old
        chmod u+w $dsttmp
        eval "$sed <$dsttmp.old >$dsttmp" || shtool_exit $?
        rm -f $dsttmp.old
    fi
    if [ ".$opt_s" = .yes ]; then
        if [ ".$opt_t" = .yes ]; then
            echo "strip $dsttmp" 1>&2
        fi
        strip $dsttmp || shtool_exit $?
    fi
    if [ ".$opt_o" != . ]; then
        if [ ".$opt_t" = .yes ]; then
            echo "chown $opt_o $dsttmp" 1>&2
        fi
        chown $opt_o $dsttmp || shtool_exit $?
    fi
    if [ ".$opt_g" != . ]; then
        if [ ".$opt_t" = .yes ]; then
            echo "chgrp $opt_g $dsttmp" 1>&2
        fi
        chgrp $opt_g $dsttmp || shtool_exit $?
    fi
    if [ ".$opt_m" != ".-" ]; then
        if [ ".$opt_t" = .yes ]; then
            echo "chmod $opt_m $dsttmp" 1>&2
        fi
        chmod $opt_m $dsttmp || shtool_exit $?
    fi

    #   determine whether to do a quick install
    #   (has to be done _after_ the strip was already done)
    quick=no
    if [ ".$opt_C" = .yes ]; then
        if [ -r $dst ]; then
            if cmp -s $src $dst; then
                quick=yes
            fi
        fi
    fi

    #   finally, install the file to the real destination
    if [ $quick = yes ]; then
        if [ ".$opt_t" = .yes ]; then
            echo "rm -f $dsttmp" 1>&2
        fi
        rm -f $dsttmp
    else
        if [ ".$opt_t" = .yes ]; then
            echo "rm -f $dst && mv $dsttmp $dst" 1>&2
        fi
        rm -f $dst && mv $dsttmp $dst
    fi
done

shtool_exit 0

##
##  manual page
##

=pod

=head1 NAME

B<shtool install> - B<GNU shtool> install(1) command

=head1 SYNOPSIS

B<shtool install>
[B<-v>|B<--verbose>]
[B<-t>|B<--trace>]
[B<-d>|B<--mkdir>]
[B<-c>|B<--copy>]
[B<-C>|B<--compare-copy>]
[B<-s>|B<--strip>]
[B<-m>|B<--mode> I<mode>]
[B<-o>|B<--owner> I<owner>]
[B<-g>|B<--group> I<group>]
[B<-e>|B<--exec> I<sed-cmd>]
I<file> [I<file> ...]
I<path>

=head1 DESCRIPTION

This command installs a one or more I<file>s to a given target I<path>
providing all important options of the BSD install(1) command.
The trick is that the functionality is provided in a portable way.

=head1 OPTIONS

The following command line options are available.

=over 4

=item B<-v>, B<--verbose>

Display some processing information.

=item B<-t>, B<--trace>

Enable the output of the essential shell commands which are executed.

=item B<-d>, B<--mkdir>

To maximize BSD compatiblity, the BSD "B<shtool> C<install -d>" usage is
internally mapped to the "B<shtool> C<mkdir -f -p -m 755>" command.

=item B<-c>, B<--copy>

Copy the I<file> to the target I<path>. Default is to move.

=item B<-C>, B<--compare-copy>

Same as B<-c> except if the destination file already exists and is
identical to the source file, no installation is done and the target
remains untouched.

=item B<-s>, B<--strip>

This option strips program executables during the installation, see
strip(1). Default is to install verbatim.

=item B<-m>, B<--mode> I<mode>

The file mode applied to the target, see chmod(1). Setting mode to
"C<->" skips this step and leaves the operating system default which is
usually based on umask(1). Some file modes require superuser privileges
to be set. Default is 0755.

=item B<-o>, B<--owner> I<owner>

The file owner name or id applied to the target, see chown(1). This
option requires superuser privileges to execute. Default is to skip this
step and leave the operating system default which is usually based on
the executing uid or the parent setuid directory.

=item B<-g>, B<--group> I<group>

The file group name or id applied to the target, see chgrp(1). This
option requires superuser privileges to execute to the fullest extend,
otherwise the choice of I<group> is limited on most operating systems.
Default is to skip this step and leave the operating system default
which is usually based on the executing gid or the parent setgid
directory.

=item B<-e>, B<--exec> I<sed-cmd>

This option can be used one or multiple times to apply one or more
sed(1) commands to the file contents during installation.

=back

=head1 EXAMPLE

 #   Makefile
 install:
      :
     shtool install -c -s -m 4755 foo $(bindir)/
     shtool install -c -m 644 foo.man $(mandir)/man1/foo.1
     shtool install -c -m 644 -e "s/@p@/$prefix/g" foo.conf $(etcdir)/

=head1 HISTORY

The B<GNU shtool> B<install> command was originally written by Ralf S.
Engelschall E<lt>rse@engelschall.comE<gt> in 1997 for B<GNU shtool>. It
was prompted by portability issues in the installation procedures of
B<OSSP> libraries.

=head1 SEE ALSO

shtool(1), umask(1), chmod(1), chown(1), chgrp(1), strip(1), sed(1).

=cut

