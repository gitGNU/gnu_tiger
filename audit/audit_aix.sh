#!/bin/sh
#
# Audit IBM AIX Script v1.1 (c) 2001 by Marc Heuse <marc@suse.de>
# This is private property. Everyone may use and change this script,
# as long as this copyright notice is kept unchanged.
# 
# Changes by Javier Fernandez-Sanguino:
# Extract additional information from the system: 
# - More /etc files
# - Look also into /usr/tmp
# - List users 
# - List configured (SMIT) services
# - Extract software inventory
#
PATH="/sbin:/usr/sbin:/bin:/usr/bin:$PATH"
HOSTNAME=`hostname`
AUDIT_NAME="AUDIT-$HOSTNAME"
AUDIT_DIR="/tmp/$AUDIT_NAME"
OUTFILE="$AUDIT_DIR.tar"

# ----- Begin local customisation -----------------
# Set this yes if you want to extract password information
CRACK_PWD="yes"
FULL_FS="yes"
# ----- End local customisation -------------------

[ "`id`" -ne 0 ] && echo "Not running as root, some information might not be extracted"

FILE_LIST_ETC="/etc/aliases /etc/sendmail.cf /etc/mail /etc/dt /etc/group \
 /etc/cron* /etc/export* /etc/xtab /etc/profile /etc/login* /etc/xtab \
 /etc/*ftp* /etc/host* /etc/inittab /etc/issue* /etc/pam* /etc/motd /etc/csh* \
 /etc/shells /etc/securetty /etc/sock* /etc/yp* /etc/filesystems /etc/hosts* \
 /etc/environment /etc/auto*"

# TBD: Actually, /etc/security/passwd is copied nevertheless (since we copy /etc/security
# completely), should we exclude it then?
if [ "$CRACK_PWD" = "yes" ] ; then
# Copy shadow and password files
	FILE_LIST_ETC="$FILE_LIST_ETC /etc/passwd /etc/security/passwd"
else
# Only copy the passwd files if shadows are used
	[ -e /etc/security/passwd ] && 	FILE_LIST_ETC="$FILE_LIST_ETC /etc/passwd"
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
tar cf etc.tar /etc/*conf* /etc/*cfg* /etc/*.d /etc/rc* /etc/tcpip \
 /etc/ssh/ssh*conf* \
 /etc/default /etc/security /sbin/rc* \
 $FILE_LIST_ETC 2> /dev/null
tar cf var.tar /var/yp /var/nis/data /var/spool/cron /var/adm/cron 2> /dev/null
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
	 -exec /bin/ls -ld {} \; >> find-s_id.out
	find $dir -perm -2 '!' -type l -exec /bin/ls -ld {} \; >> find-write.out
done

# List directories
/bin/ls -al / > ls-root.out
/bin/ls -alR /etc > ls-etc.out
/bin/ls -alRL /dev > ls-dev.out
/bin/ls -al /tmp /*/tmp/ > ls-tmp.out
/bin/ls -alR /var/log /var/adm /var/spool /var/spool/mail /var/user* > ls-var.out
/bin/ls -lL /dev/*rmt* /dev/*floppy* /dev/fd0* /dev/*audio* /dev/*mix* > ls-dev-spec.out 2> /dev/null
/bin/ls -alR /usr/adm /usr/bin/mail/  /usr/*/adm/ > ls-usr.out
/bin/ls -alR /opt /software /usr/local > ls-software.out 2> /dev/null
/bin/ls -alRL /home > ls-home.out

# Mounted file systems
mount > mount.out

# RPC programs
rpcinfo -p > rpcinfo.out 2> /dev/null

# Processes
ps -elf > ps.out
# Patches
instfix -a > instfix.out
# System information
uname -a > uname.out
oslevel >> uname.out
oslevel -r >>uname.out
# Users connected to the system
last -25 > last_25.out
last -5 root > last_root.out
xhost > xhost.out 2> /dev/null
# History of user running the audit
history > history.out
# Open listeners
netstat -an > netstat-an.out
# Interfaces
netstat -i > netstat-i.out
# Routing
netstat -rn > netstat-rn.out
# Process-sockets
[ -n "`which lsof`" ] && lsof -n >lsof.out
# Arp information
arp -n >arp.out 2>/dev/null

# Environment and Umask
echo "$OLD_ENV" > env.out
echo "$OLD_UMASK" > umask.out

# Disk
df -kl > df-local.out
# All disks
df -k > df.out


# Review TCP/IP configuration:
no -a > no.out
# Inet services
inetserv -s -S -X >inet-serv.out 2> /dev/null
hostent -S >hostent.out  2> /dev/null
namerslv -s -I >namesrv.out 2> /dev/null
lssrc -a >lssrc-all.out 2> /dev/null
lssrc -g tcpip >lssrc-tcpip.out 2> /dev/null
lssrc -ls inetd >lssrc-inetd.out 2> /dev/null
lssrc -g nfs >lssrc-nfs.out 2> /dev/null
lsdev -C -c if >lsdev-if.out 2> /dev/null

# Password inconsistencies
/usr/bin/pwdck -n ALL >pwdck.out 2>&1
/usr/bin/grpck -n ALL >grpck.out 2>&1



# List users
lsuser -f ALL >lsuser.out
# Software inventory
lslpp -l > sw-inv.out 2> /dev/null
lslpp -h > sw-inv-host.out 2> /dev/null

cd /tmp
tar cf "$OUTFILE" "$AUDIT_NAME"
compress -c "$OUTFILE" >> "$OUTFILE".Z
/bin/rm -f "$OUTFILE"
echo
echo "$OUTFILE".Z is finished, you may delete "$AUDIT_DIR" now.
