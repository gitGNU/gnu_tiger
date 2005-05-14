#!/bin/sh
#
# Audit HP-UX 9.x/10.x Script v1.1 (c) 2001 by Marc Heuse <marc@suse.de>
# This is private property. Everyone may use and change this script,
# as long as this copyright notice is kept unchanged.
#
# 
# Changes by Javier Fernandez-Sanguino:
# - Extract more information from /etc
# - Extract information from TCB
# - Extract crontabs from /usr
# -
#
PATH="/sbin:/usr/sbin:/bin:/usr/bin:/usr/lbin:$PATH"
HOSTNAME=`hostname`
AUDIT_NAME="AUDIT-$HOSTNAME"
AUDIT_DIR="/tmp/$AUDIT_NAME"
OUTFILE="$AUDIT_DIR.tar"

# ----- Begin local customisation -----------------
# Set this yes if you want to extract password information
CRACK_PWD="yes"
# ----- End local customisation -------------------

[ "`id`" -ne 0 ] && echo "Not running as root, some information might not be extracted"

FILE_LIST_ETC="/etc/aliases /etc/sendmail.cf /etc/passwd /etc/group \
 /etc/cron* /etc/export* /etc/profile /etc/login* /etc/inittab\
 /etc/*ftp* /etc/host* /etc/inittab /etc/issue* /etc/motd /etc/csh* \
 /etc/shells /etc/securetty /etc/sock* /etc/yp* /etc/SnmpAgent.d/ \
 /etc/ntp.conf /etc/fstab /etc/mail /etc/pam.conf"

if [ "$CRACK_PWD" = "yes" ] ; then
	FILE_LIST_ETC="$FILE_LIST_ETC /etc/shadow "
fi

OLD_UMASK=`umask`
OLD_ENV=`env`
umask 077
set -o noclobber
> "$OUTFILE" || exit 1
> "$OUTFILE.Z" || exit 1
if [ -e "$AUDIT_DIR" ]; then
    mv "$AUDIT_DIR" "$AUDIT_DIR".old
fi
mkdir "$AUDIT_DIR" || exit 1
cd "$AUDIT_DIR" || exit 1
set +o noclobber
# Extract information from the system
tar cf etc.tar /tcb /etc/*conf* /etc/*cfg* /etc/*.d /etc/rc* /etc/httpd \
 /etc/default /etc/security /sbin/init.d /etc/rc* /sbin/rc* /etc/ssh/ssh*conf* \
 /etc/mail/sendmail.cf  $FILE_LIST_ETC 2> /dev/null
tar cf var.tar /var/yp /var/nis/data /var/spool/cron /var/adm/cron 2> /dev/null
tar cf usr.tar /usr/spool/cron 2> /dev/null
tar cf tcb.tar /tcb/files 2> /dev/null
tar cf home.tar /.*bash* /.netrc /.rhosts /.log* /.*csh* /.Xa* \
 /.prof* /home/*/.*bash* /home/*/.netrc /home/*/.rhosts \
 /home/*/.log* /home/*/.*csh* /home/*/.Xa* /home/*/.prof* \
 /root/.*bash* /root/.netrc /root/.rhosts /root/.log* /root/.*csh* \
 /root/.Xa* /root/.prof* 2> /dev/null

# Find stuff that might be a problem to the system
# Setuid files
find / \( -perm -4000 -o -perm -2000 -o -perm -1000 \) -type f \
 -exec /bin/ls -ld {} \; > find-s_id.out
# All-Writable stuff
find / -perm -2 '!' -type l -exec /bin/ls -ld {} \; > find-write.out

# List directories
/bin/ls -al / > ls-root.out
/bin/ls -alR /etc > ls-etc.out
/bin/ls -alRL /dev > ls-dev.out
/bin/ls -al /tmp > ls-tmp.out
/bin/ls -alR /var/adm /var/spool /var/mail > ls-var.out
/bin/ls -lL /dev/*rmt* /dev/*floppy* /dev/fd0* /dev/*audio* /dev/*mix* > ls-dev-spec.out 2> /dev/null
/bin/ls -alR /opt /software /usr/local > ls-software.out 2> /dev/null

# Mounted file systems
mount > mount.out

# RPC programs
rpcinfo -p > rpcinfo.out 2>/dev/null
# Processes
ps -ef > ps.out
# Patches
swlist > patch.out  2>/dev/null
# System information
uname -a > uname.out
getprivgrp > hpux-getprivgrp.out  2>/dev/null
# Users connected to the system
last -25 > last_25.out
last -5 root > last_root.out
# History of user running the audit
history > history.out
# Environment and Umask
echo "$OLD_ENV" > env.out
echo "$OLD_UMASK" > umask.out
# Open listeners
netstat -an > netstat-an.out
# Process-sockets
which lsof >/dev/null 2>&1 && lsof -n >lsof.out
# Routing
netstat -rn > netstat-rn.out

# Trusted mode
getprdef -r >getprdef.out 2>/dev/null
getprdef -m umaxlntr >>getprdef.out 2>/dev/null

echo "$OLD_ENV" > env.out
echo "$OLD_UMASK" > umask.out

#TODO:
#netune parameters!

cd /tmp
tar cf "$OUTFILE" "$AUDIT_NAME"
compress -c "$OUTFILE" >> "$OUTFILE".Z
/bin/rm -f "$OUTFILE"
echo
echo "$OUTFILE".Z is finished, you may delete "$AUDIT_DIR" now.
