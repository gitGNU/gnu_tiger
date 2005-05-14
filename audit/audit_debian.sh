#!/bin/sh
#
# Audit Debian GNU/Linux Script v1.1 (c) 2005 by Javier Fernandez-Sanguino
# based on
# Audit SuSE Linux Script v1.1 (c) 2001 by Marc Heuse <marc@suse.de>
# This is private property. Everyone may use and change this script,
# as long as this copyright notice is kept unchanged.
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

FILE_LIST_ETC="/etc/aliases /etc/group \
 /etc/cron* /etc/export* /etc/profile /etc/login* \
 /etc/*ftp* /etc/host* /etc/inittab /etc/issue* /etc/motd /etc/csh* \
 /etc/shells /etc/securetty /etc/sock* /etc/yp* /etc/fstab \
 /etc/snmp/ /etc/hosts*  /etc/sudoers /etc/securetty /etc/security/ 
 /etc/default/  /sbin/init.d /etc/pam.d/* /etc/cron* \
 /etc/*conf* /etc/*cfg* /etc/*.d /etc/rc* \
 /usr/local/etc/ "
# Service specific files 
# This list does not attempt to capture all, just the most common files:
# Notice that many service files will be captured with the previous "/etc/*conf*" above
FILE_LIST_ETC="$FILE_LIST_ETC /etc/mail/ /etc/sendmail.cf  /etc/httpd /etc/samba/ \
   /etc/bind /etc/named /etc/postfix /etc/postgresql /etc/mysql /etc/qmail \
   /etc/courier /etc/cups /etc/dhcp /etc/dhcp3 \
   /etc/ssh/ssh*conf /etc/xinetd* \
   /etc/ldap /etc/openldap /etc/squid"
# Debian-specific configuration files
FILE_LIST_ETC="$FILE_LIST_ETC /etc/apt /etc/dpkg \
  /etc/exim4/ /etc/exim/ \
  /etc/apache*/*conf /etc/php4/apache/php.ini"
if [ "$CRACK_PWD" = "yes" ] ; then
# Copy shadow and password files
	FILE_LIST_ETC="$FILE_LIST_ETC /etc/passwd /etc/shadow"
else
# Only copy the passwd files if shadows are used
	[ -e /etc/shadow ] && 	FILE_LIST_ETC="$FILE_LIST_ETC /etc/passwd"
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

[ "`id -u`" -ne 0 ] && echo "Not running as root, some information might not be extracted"

# Extract information from the system
tar cf etc.tar $FILE_LIST_ETC 2> /dev/null
tar cf var.tar /var/yp /var/nis/data /var/spool/cron 2> /dev/null

# NOTE: If using automounter this will fail (should abort before)
tar cf home.tar /.*bash* /.netrc /.rhosts /.log* /.*csh* /.Xa* \
 /.prof* /home/*/.*bash* /home/*/.netrc /home/*/.rhosts \
 /home/*/.log* /home/*/.*csh* /home/*/.Xa* /home/*/.prof* \
 /root/.*bash* /root/.netrc /root/.rhosts /root/.log* /root/.*csh* \
 /root/.Xa* /root/.prof* 2> /dev/null
# Process accounting
if [ -d /var/log/sa ] ; then
	tar cf system-act.tar /var/log/sa/ 2>/dev/null
fi
# Find stuff that might be a problem to the system
# Setuid files and All-Writable stuff
if [ "$FULL_fs" = "yes" ] ; then
	DIRS="/"
else
# Finding in the whole filesystem maybe too much
# restrict to a specific set of directories
	DIRS="/bin /usr /etc /dev /var /boot /lib /opt /sbin /tmp"
fi

for dir in $DIRS; do 
	find $dir \( -perm -4000 -o -perm -2000 -o -perm -1000 \) -type f \
	 -exec /bin/ls -ld {} \; >> find-s_id.out 2>&1
	find $dir -perm -2 '!' -type l -exec /bin/ls -ld {} \; >> find-write.out 2>&1
done

# List directories
/bin/ls -al / > ls-root.out 2>&1
# Configuration files 
/bin/ls -alR /etc > ls-etc.out 2>&1
# Devices
/bin/ls -alRL /dev > ls-dev.out 2>&1
# Temporary files
/bin/ls -al /tmp > ls-tmp.out 2>&1
/bin/ls -al /var/tmp > ls-var-tmp.out 2>&1
# Log and Spool files
/bin/ls -alR /var/log /var/adm /var/spool /var/spool/mail > ls-var.out 2>&1
# Extra software
/bin/ls -alR /opt /software /usr/local > ls-software.out 2>&1
# Home directories (comment if this is automouted)
/bin/ls -alRL /home > ls-home.out 2>&1
# Kernel files
/bin/ls -alR /vmlin* /boot > ls-boot.out 2>&1
# Loaded modules
lsmod >lsmod.out 2>&1

# Mounted file systems
mount > mount.out 2>&1
# RPC services
rpcinfo -p > rpcinfo.out  2>&1
# Exported filesystems
[ -n "`which showmount`" ]  && showmount -e >exports.out 2>&1
# Processes
ps auxwww > ps.out 2>&1
# Patches
dpkg --get-selections "*" > dpkg.out 2>&1
# Debsums
which debsums >/dev/null 2>&1 && debsums >debsums.out 2>&1

# System information
# Machine name
uname -a > uname.out  2>&1
# Machine OS and version
cat /etc/*version* >> uname.out 2>&1
# Users connected to the system
last -25 > last_25.out 2>&1
last -5 root > last_root.out 2>&1
# X access controls
xhost > xhost.out  2>&1
xauth list >xauth.out 2>&1
# History of user running the audit
history > history.out 2>&1

# Open listeners
netstat -an > netstat-an.out 2>&1
# Routing
netstat -rn > netstat-rn.out 2>&1
# Process-sockets
which lsof >/dev/null 2>&1 && lsof -n >lsof.out 2>&1
# Arp information
arp -n >arp.out 2>&1

# Environment and Umask
echo "$OLD_ENV" > env.out 2>&1
echo "$OLD_UMASK" > umask.out 2>&1

# Disk
df -kl > df-local.out 2>&1
# All disks
df -k > df.out 2>&1

# IP Filtering 
# For 2.4 kernels
iptables -nL >iptables.out 2>&1
# For 2.2 kernels
ipchains -L -n -v > ipchains.out 2>&1
# For older kernels
ipfwadm  -L -n -v > ipfwadm.out 2>&1


# Kernel parameters (not all might apply)
# Note: This is maybe too exaggerated (might it introduce issues? (jfs)

# TCP/IP parameters
# All the parameters (this might be risky...)
for i in `find /proc/sys/net/ipv4 -type f`; do
    [ "$i" != "/proc/sys/net/ipv4/route/flush" ] && {
    echo -n "$i: " >> proc.out
    cat $i >> proc.out 2>&1
    echo "" >> proc.out 
   }
done
# Safer:
#for i icmp_echo_ignore_broadcasts icmp_echo_ignore_all tcp_syncookies \
# ip_always_defrag ip_forward ; do
#    echo -n "/proc/sys/net/ipv4/$i: " >> proc.out
#    cat /proc/sys/net/ipv4/$i >> proc.out
#    echo "" >> proc.out
#done
#for i in /proc/sys/net/ipv4/conf/*; do
#    for j in accept_redirects accept_source_route rp_filter bootp_relay \
#     mc_forwarding log_martians proxy_arp secure_redirects; do
#        echo -n "$i/$j: " >> proc.out
#        cat $i/$j >> proc.out
#        echo "" >> proc.out
#    done
#done

# Finish up, compress the output
cd /tmp
COMPRESS=1
tar cf "$OUTFILE" "$AUDIT_NAME"
if [ -n "`which compress`" ] ; 
then
	compress -c "$OUTFILE" >> "$OUTFILE".Z
elif [ -n "`which gzip`" ] ;
then
	gzip -c "$OUTFILE" >> "$OUTFILE".gz
	COMPRESS=2
else
	COMPRESS=0
fi
if [ "$COMPRESS" -eq 1 ] ; then
	/bin/rm -f "$OUTFILE"
	echo
	echo -n "$OUTFILE.Z is finished"
elif [ "$COMPRESS" -eq 2 ] ; then
	/bin/rm -f "$OUTFILE"
	echo
	echo "$OUTFILE.gz is finished"
else 
	echo
	echo "$OUTFILE is finished"
fi
echo ", you may delete '$AUDIT_DIR' now."

exit 0