#
# Regular cron jobs for the tiger package
#
0 * * * *      root    test -x /usr/sbin/tigercron && /usr/sbin/tigercron -q
