#!/bin/sh
#
# Audit Nokia Boxes Script v1.3 (c) 2001 by Marc Heuse
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
PATH="/sbin:/usr/sbin:/bin:/usr/bin:$PATH"
HOSTNAME=`hostname`
AUDIT_NAME="AUDIT-$HOSTNAME"
AUDIT_DIR="/tmp/$AUDIT_NAME"
OUTFILE="$AUDIT_DIR.tar"

OLD_UMASK=`umask`
OLD_ENV=`env`
umask 077
#set -o noclobber	# not supported
> "$OUTFILE" || exit 1
> "$OUTFILE.Z" || exit 1
#set +o noclobber
if [ -e "$AUDIT_DIR" ]; then
    mv "$AUDIT_DIR" "$AUDIT_DIR".old
fi
mkdir "$AUDIT_DIR" || exit 1
cd "$AUDIT_DIR" || exit 1

tar cf etc.tar /var/etc
tar cf conf.tar /config /opt/Fire*/conf /opt/ISS/Real*/*policy /opt/cgi-bin/.h* \
 /opt/NETA*/usr/local/etc/mgmt/*txt /opt/NETA*/usr/local/etc/mgmt/*conf

find / \( -perm -4000 -o -perm -2000 \) -type f \
 -exec /bin/ls -ld {} \; > find-s_id.out
find / -perm -2 '!' -type l -exec /bin/ls -ld {} \; > find-write.out

/bin/ls -alRL /etc > ls-etc.out
/bin/ls -alRL /dev > ls-dev.out
/bin/ls -al /tmp /opt/tmp > ls-tmp.out
/bin/ls -alR /var/log /var/adm /var/spool /var/spool/mail > ls-var.out 2> /dev/null
/bin/ls -lL /dev/*rmt* /dev/*floppy* /dev/fd0* /dev/*audio* /dev/*mix* > ls-dev-spec.out 2> /dev/null
/bin/ls -alR /opt /software /usr/local > ls-software.out 2> /dev/null

mount > mount.out
rpcinfo -p > rpcinfo.out 2>/dev/null
ps auxwww > ps.out
uname -a > uname.out
last -25 > last_25.out
last -5 root > last_root.out
history > history.out
xhost > xhost.out 2> /dev/null
netstat -an > netstat-an.out
netstat -rn > netstat-rn.out

echo "$OLD_ENV" > env.out
echo "$OLD_UMASK" > umask.out

cd /tmp
tar cf "$OUTFILE" "$AUDIT_NAME"
compress -c "$OUTFILE" >> "$OUTFILE".Z
/bin/rm -f "$OUTFILE"
echo
echo "$OUTFILE".Z is finished, you may delete "$AUDIT_DIR" now.
