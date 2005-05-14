#!/bin/sh
#
# Audit SuSE Linux Script v1.4 (c) 2002 by Marc Heuse
# <mheuse@kpmg.com> | <marc@suse.de> | http://www.suse.de/~marc/audit/
# This is private property. Everyone may use and change this script,
# as long as this copyright notice is kept unchanged.
#
PATH="/sbin:/usr/sbin:/bin:/usr/bin:$PATH"
HOSTNAME=`hostname`
AUDIT_NAME="AUDIT-$HOSTNAME"
AUDIT_DIR="/tmp/$AUDIT_NAME"
OUTFILE="$AUDIT_DIR.tar"

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

tar cf etc.tar /etc/*conf* /etc/*cfg* /etc/*.d /etc/rc* /etc/httpd \
 /etc/default /etc/security /sbin/init.d /etc/ssh/ssh*conf* \
 /etc/aliases /etc/sendmail.cf /etc/passwd /etc/group \
 /etc/cron* /etc/export* /etc/profile /etc/login* /etc/shadow \
 /etc/*ftp* /etc/host* /etc/inittab /etc/issue* /etc/motd /etc/csh* \
 /etc/shells /etc/securetty /etc/sock* /etc/yp* 2> /dev/null
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
/bin/ls -alRL /dev > ls-dev.out
/bin/ls -al /tmp > ls-tmp.out
/bin/ls -alR /var/log /var/adm /var/spool /var/spool/mail > ls-var.out 2> /dev/null
/bin/ls -lL /dev/*rmt* /dev/*floppy* /dev/fd0* /dev/*audio* /dev/*mix* > ls-dev-spec.out 2> /dev/null
/bin/ls -alR /opt /software /usr/local > ls-software.out 2> /dev/null

mount > mount.out
rpcinfo -p > rpcinfo.out 2>/dev/null
ps auxwww > ps.out
rpm -qa > rpm.out 2> /dev/null
uname -a > uname.out
cat /etc/*release* >> uname.out 2> /dev/null
last -25 > last_25.out
last -5 root > last_root.out
history > history.out
xhost > xhost.out 2> /dev/null
netstat -an > netstat-an.out
netstat -rn > netstat-rn.out

ipfwadm  -L -n -v > ipfwadm.out 2> /dev/null
iptables -L -n -v > iptables.out 2> /dev/null
ipchains -L -n -v > ipchains.out 2> /dev/null

echo "$OLD_ENV" > env.out
echo "$OLD_UMASK" > umask.out

for i in icmp_echo_ignore_broadcasts icmp_echo_ignore_all tcp_syncookies \
 ip_always_defrag ip_forward igmp_max_memberships icmp_destunreach_rate; do
    echo -n "/proc/sys/net/ipv4/$i: " >> proc.out
    cat /proc/sys/net/ipv4/$i >> proc.out 2> /dev/null
    echo "" >> proc.out
done
for i in /proc/sys/net/ipv4/conf/*; do
    for j in accept_redirects accept_source_route rp_filter bootp_relay \
     mc_forwarding log_martians proxy_arp secure_redirects; do
        echo -n "$i/$j: " >> proc.out
        cat $i/$j >> proc.out 2> /dev/null
        echo "" >> proc.out
    done
done

cd /tmp
tar cf "$OUTFILE" "$AUDIT_NAME"
compress -c "$OUTFILE" >> "$OUTFILE".Z
/bin/rm -f "$OUTFILE"
echo
echo "$OUTFILE".Z is finished, you may delete "$AUDIT_DIR" now.
