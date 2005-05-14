#!/bin/sh
#
# Audit IBM AIX Script v1.1 (c) 2001 by Marc Heuse <marc@suse.de>
# This is private property. Everyone may use and change this script,
# as long as this copyright notice is kept unchanged.
# 
# Changes by Javier Fernandez-Sanguino
#
PATH="/sbin:/usr/sbin:/bin:/usr/bin"
HOSTNAME=`hostname`
AUDIT_NAME="AUDIT-$HOSTNAME"
AUDIT_DIR="/tmp/$AUDIT_NAME"
OUTFILE="$AUDIT_DIR.tar"

FILE_LIST_ETC="/etc/aliases /etc/sendmail.cf /etc/passwd /etc/group \
 /etc/cron* /etc/export* /etc/profile /etc/login* /etc/xtab \
 /etc/*ftp* /etc/host* /etc/inittab /etc/issue* /etc/motd /etc/csh* \
 /etc/shells /etc/securetty /etc/sock* /etc/yp*"

[ "`id`" -ne 0 ] && echo "Not running as root, some information might not be extracted"

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

tar cf etc.tar /etc/*conf* /etc/*cfg* /etc/*.d /etc/rc* /etc/ssh/ssh*conf* \
 /etc/default /etc/security /sbin/rc* \
 $FILE_LIST_ETC 2> /dev/null
tar cf var.tar /var/yp /var/nis/data /var/spool/cron 2> /dev/null
tar cf home.tar /.*bash* /.netrc /.rhosts /.log* /.*csh* /.Xa* \
 /.prof* /home/*/.*bash* /home/*/.netrc /home/*/.rhosts \
 /home/*/.log* /home/*/.*csh* /home/*/.Xa* /home/*/.prof* \
 /root/.*bash* /root/.netrc /root/.rhosts /root/.log* /root/.*csh* \
 /root/.Xa* /root/.prof* 2> /dev/null
find / \( -perm -4000 -o -perm -2000 \) -type f \
 -exec /bin/ls -ld {} \; > find-s_id.out
find / -perm -2 '!' -type l -exec /bin/ls -ld {} \; > find-write.out

# List directories
/bin/ls -al / > ls-root.out
/bin/ls -alR /etc > ls-etc.out
/bin/ls -alRL /dev > ls-dev.out
/bin/ls -al /tmp > ls-tmp.out
/bin/ls -alR /var/log /var/adm /var/spool /var/spool/mail > ls-var.out

# Mounted file systems
mount > mount.out

# RPC programs
rpcinfo -p > rpcinfo.out

# Processes
ps -elf > ps.out
# Patches
instfix -a > instfix.out
# System information
uname -a > uname.out
oslevel >> uname.out
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
# Routing
netstat -rn > netstat-rn.out
no -a > no.out

cd /tmp
tar cf "$OUTFILE" "$AUDIT_NAME"
compress -c "$OUTFILE" >> "$OUTFILE".Z
/bin/rm -f "$OUTFILE"
echo
echo "$OUTFILE".Z is finished, you may delete "$AUDIT_DIR" now.
