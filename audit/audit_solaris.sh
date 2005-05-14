#!/usr/bin/ksh
# #!/bin/sh <- does not support noclobber mode
#
# Audit Sun Solaris Script v1.3 (c) 2001 by Marc Heuse
# <mheuse@kpmg.com> | <marc@suse.de> | http://www.suse.de/~marc/audit/
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#  
# You can also find a copy of the GNU General Public License at
# http://www.gnu.org/licenses/licenses.html#TOCLGPL
#
# v1.4 Javier Fernandez-Sanguino <jfs@computer.org>
# Changes:
# - added notes
# - added tar of /usr/local/etc (some Solaris packages install there?)
# - added additional files for /etc/ (might be interesting)
# - added an option to either obtain the passwd files  (CRACK_PWD)
# - added an option to go through the full filesystem (FULL_FS) or not
#
# Notes (jfs): This script sometimes core dumps in Solaris 8. It should
# be analised to determine where the issue is.
#
PATH="/sbin:/usr/sbin:/bin:/usr/bin:/usr/ucb:$PATH"
HOSTNAME=`hostname`
AUDIT_NAME="AUDIT-$HOSTNAME"
AUDIT_DIR="/tmp/$AUDIT_NAME"
OUTFILE="$AUDIT_DIR.tar"

# ----- Begin local customisation -----------------
# Set this yes if you want to extract password information
CRACK_PWD="yes"
FULL_FS="yes"
# ----- End local customisation -------------------

# TODO: This should be checked automatically and abort the script...

echo "Warning: if the system is not correctly set up, e.g. automounter \
points are still there, but the automounter service is not running, the \
script might/will hang for the find commands."

OLD_UMASK=`umask`
OLD_ENV=`env`
umask 077
set -o noclobber
> "$OUTFILE" || exit 1
> "$OUTFILE.Z" || exit 1
set +o noclobber
if [ -e "$AUDIT_DIR" ]; then
    mv "$AUDIT_DIR" "$AUDIT_DIR".old
fi
mkdir "$AUDIT_DIR" || exit 1
cd "$AUDIT_DIR" || exit 1

[ "`id -u`" -ne 0 ] && echo "Not running as root, some information might not be extracted"

# Extract information from the system
tar cf etc.tar /etc/*conf* /etc/*cfg* /etc/*.d /etc/rc* /sbin/rc* \
 /etc/default /etc/dfs /etc/inet /etc/security /etc/ssh/ssh*conf* \
 /etc/aliases /etc/sendmail.cf /etc/group \
 /etc/cron* /etc/export* /etc/profile /etc/login* /etc/.login /etc/logout  \
 /etc/*ftp* /etc/host* /etc/inittab /etc/issue* /etc/motd /etc/csh* \
 /etc/shells /etc/securetty /etc/sock* /etc/system* /etc/yp* /usr/local/etc/*  \
 /etc/auto* /etc/dumpdates /etc/ethers /etc/vfstab /etc/rmtab /etc/vold.conf \
 /etc/pam* /etc/ttydefs /etc/nsswitch.conf /etc/resolv.conf /etc/printers.conf \
 /etc/rpcsec /etc/snmp /etc/dmi /etc/dhcp /etc/cron.d /etc/nfs /etc/nfssec.conf \
 /etc/mail /etc/apache /etc/rpld.conf /etc/dtconfig /etc/named.conf \
 /etc/netgroups /etc/hosts.* /etc/X*hosts /etc/ppp /etc/rpcsec \
 /etc/hostname* /etc/netconfig /etc/nodename /etc/defaultrouter /etc/uucp/* 2> /dev/null
if [ "$CRACK_PWD" = "yes" ] ; then
# Copy shadow and password files
	tar cf etc-pwd.tar /etc/passwd* /etc/opass* /etc/sha* 2> /dev/null
else
# Only copy the passwd files if shadows are used
	[ -e /etc/shadow ] && tar cf etc-pwd.tar /etc/passwd* /etc/opass* 2> /dev/null
fi

tar cf var.tar /var/yp /var/nis/data /var/spool/cron 2> /dev/null

# NOTE: If using automounter this will fail (should abort before)
tar cf home.tar /.*bash* /.netrc /.rhosts /.log* /.*csh* /.Xa* \
 /.prof* /home/*/.*bash* /home/*/.netrc /home/*/.rhosts \
 /home/*/.log* /home/*/.*csh* /home/*/.Xa* /home/*/.prof* \
 /root/.*bash* /root/.netrc /root/.rhosts /root/.log* /root/.*csh* \
 /root/.Xa* /root/.prof* 2> /dev/null

# Find stuff that might be a problem to the system
# Setuid files and All-Writable stuff
if [ "$FULL_fs" = "yes" ] ; then
	DIRS="/"
else
# Finding in the whole filesystem maybe too much
# restrict to a specific set of directories
	DIRS="/bin /usr /etc /dev /var /kernel /lib /opt /sbin /sys /vol /tmp"
fi

for dir in $DIRS; do 
	find $dir \( -perm -4000 -o -perm -2000 -o -perm -1000 \) -type f \
	 -exec /bin/ls -ld {} \; >> find-s_id.out 2>&1
	find $dir -perm -2 '!' -type l -exec /bin/ls -ld {} \; >> find-write.out 2>&1
done


# List directories
/bin/ls -al / > ls-root.out 2>&1 
/bin/ls -alR /etc > ls-etc.out 2>&1
/bin/ls -alRL /dev /devices > ls-dev.out 2>&1
/bin/ls -al /tmp /var/tmp /usr/tmp > ls-tmp.out 2>&1
/bin/ls -alR /var/log /var/adm /var/spool /var/audit > ls-var.out 2>&1
/bin/ls -lL /dev/*rmt* /dev/*floppy* /dev/fd0* /dev/*audio* /dev/*mix* > ls-dev-spec.out 2>&1
/bin/ls -alR /opt /software /usr/local > ls-software.out 2>&1

# Mounted file systems
mount > mount.out 2>&1

# RPC programs
rpcinfo -p > rpcinfo.out 2>&1
# Processes
ps -elf > ps.out 2>&1
showrev -a > showrev.out 2>&1

# Installed software (through the package system)
pkginfo -l > pkginfo.out 2>&1

# Patches
patchadd -p > patchadd.out 2>&1
# Takes to long
#pkgchk > pkgchk.out 2>&1

# System information
uname -a > uname.out 2>&1
# Users connected to the system
last -25 > last_25.out 2>&1
last -5 root > last_root.out 2>&1
# Note: xhost might block sometimes (when X11 running and no display)
xhost > xhost.out 2> /dev/null 2>&1
# Xauthorities
xauth list >xauth.out 2>&1
eeprom security-mode > eeprom.out 2>&1
# History of user running the audit
history > history.out 2>&1
# Open listeners
netstat -an > netstat-an.out 2>&1
# Interfaces
netstat -i > netstat-i.out 2>&1
# Routing
netstat -rn > netstat-rn.out 2>&1
# Process-sockets
which lsof >/dev/null 2>&1 && lsof -n 2>&1
# Arp information
arp -na >arp.out 2>&1
# Environment and Umask

echo "$OLD_ENV" 2>&1
echo "$OLD_UMASK" 2>&1

# Definition of shared libraries (Solaris 8 and later)
crle -v >crl.out 2>&1

# Kernel modules
modinfo >modinfo.out 2>&1

# Disk
df -kl > df-local.out 2>&1
# All disks
df -k > df.out 2>&1
# Swap
swal -l >swap.out 2>&1

# Ndd parameters

# IP
for i in ip_forwarding ip_forward_src_routed ip_respond_to_timestamp \
         ip_respond_to_timestamp_broadcast   ip_ignore_redirect \
         ip_strict_dst_multihoming           ip_forward_directed_broadcasts \
         ip_respond_to_echo_broadcast        ip_respond_to_address_mask_broadcast \
         ip_ire_arp_interval ip_ire_flush_interval ip_strict_dst_multihoming \
         ip_send_redirects ip6_forwarding ip6_send_redirects ip6_ignore_redirect; do 
    echo "$i: " >> ndd.out 
    ndd /dev/ip "$i" >> ndd.out 2>&1
    echo "" >> ndd.out
done

# ARP
for i in arp_cleanup_interval; do
    echo "$i: " >> ndd.out
    ndd /dev/arp "$i" >> ndd.out 2>&1
    echo "" >> ndd.out
done

# TCP
for i in tcpip_abort_cinterval tcp_conn_req_max_q tcp_conn_req_max_q0 tcp_strong_iss \
   tcp_extra_priv_ports tcp_time_wait_interval tcp_ip_abort_cinterval; do
    echo "$i: " >> ndd.out
    ndd /dev/tcp "$i" >> ndd.out 2>&1
    echo "" >> ndd.out
done

cd /tmp
tar cf "$OUTFILE" "$AUDIT_NAME"
compress -c "$OUTFILE" >> "$OUTFILE".Z
/bin/rm -f "$OUTFILE"
echo
echo "$OUTFILE".Z is finished, you may delete "$AUDIT_DIR" now.
