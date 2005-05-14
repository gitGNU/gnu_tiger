#!/usr/bin/ksh
# #!/bin/sh <- does not support noclobber mode
#
# Audit Sun Solaris Script v1.3 (c) 2001 by Marc Heuse
# <mheuse@kpmg.com> | <marc@suse.de> | http://www.suse.de/~marc/audit/
# This is private property. Everyone may use and change this script,
# as long as this copyright notice is kept unchanged.
#
PATH="/sbin:/usr/sbin:/bin:/usr/bin:/usr/ucb:$PATH"
HOSTNAME=`hostname`
AUDIT_NAME="AUDIT-$HOSTNAME"
AUDIT_DIR="/tmp/$AUDIT_NAME"
OUTFILE="$AUDIT_DIR.tar"

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

tar cf etc.tar /etc/*conf* /etc/*cfg* /etc/*.d /etc/rc* /sbin/rc* \
 /etc/default /etc/dfs /etc/inet /etc/security /etc/ssh/ssh*conf* \
 /etc/aliases /etc/sendmail.cf /etc/passwd* /etc/group \
 /etc/sha* /etc/cron* /etc/export* /etc/profile /etc/login* \
 /etc/*ftp* /etc/host* /etc/inittab /etc/issue* /etc/motd /etc/csh* \
 /etc/shells /etc/securetty /etc/sock* /etc/system /etc/yp* 2> /dev/null
tar cf var.tar /var/yp /var/nis/data /var/spool/cron 2> /dev/null
tar cf home.tar /.*bash* /.netrc /.rhosts /.log* /.*csh* /.Xa* \
 /.prof* /home/*/.*bash* /home/*/.netrc /home/*/.rhosts \
 /home/*/.log* /home/*/.*csh* /home/*/.Xa* /home/*/.prof* \
 /root/.*bash* /root/.netrc /root/.rhosts /root/.log* /root/.*csh* \
 /root/.Xa* /root/.prof* 2> /dev/null

find / \( -perm -4000 -o -perm -2000 \) -type f \
 -exec /bin/ls -ld {} \; > find-s_id.out
find / -perm -2 '!' -type l -exec /bin/ls -ld {} \; > find-write.out

/bin/ls -alR /etc > ls-etc.out
/bin/ls -alRL /dev /devices > ls-dev.out
/bin/ls -al /tmp > ls-tmp.out
/bin/ls -alR /var/log /var/adm /var/spool > ls-var.out 2> /dev/null
/bin/ls -lL /dev/*rmt* /dev/*floppy* /dev/fd0* /dev/*audio* /dev/*mix* > ls-dev-spec.out 2> /dev/null
/bin/ls -alR /opt /software /usr/local > ls-software.out 2> /dev/null

mount > mount.out
rpcinfo -p > rpcinfo.out 2> /dev/null
ps -elf > ps.out
showrev -a > showrev.out 2> /dev/null
patchadd -p > patchadd.out 2> /dev/null
uname -a > uname.out
last -25 > last_25.out
last -5 root > last_root.out
xhost > xhost.out 2> /dev/null
eeprom security-mode > eeprom.out 2> /dev/null
history > history.out
netstat -an > netstat-an.out
netstat -rn > netstat-rn.out

echo "$OLD_ENV" > env.out
echo "$OLD_UMASK" > umask.out

for i in ip_forwarding ip_forward_src_routed ip_respond_to_timestamp \
         ip_respond_to_timestamp_broadcast   ip_ignore_redirect \
         ip_strict_dst_multihoming           ip_forward_directed_broadcasts \
         ip_respond_to_echo_broadcast        ip_respond_to_address_mask_broadcast; do
    echo "$i: " >> ndd.out
    ndd /dev/ip "$i" >> ndd.out 2> /dev/null
    echo "" >> ndd.out
done

for i in tcp_strong_iss; do
    echo "$i: " >> ndd.out
    ndd /dev/tcp "$i" >> ndd.out 2> /dev/null
    echo "" >> ndd.out
done

cd /tmp
tar cf "$OUTFILE" "$AUDIT_NAME"
compress -c "$OUTFILE" >> "$OUTFILE".Z
/bin/rm -f "$OUTFILE"
echo
echo "$OUTFILE".Z is finished, you may delete "$AUDIT_DIR" now.
