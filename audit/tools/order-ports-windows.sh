#!/bin/sh
echo "TCP ports"
echo "---------"
cat report.txt |grep "LISTENING" |
perl -ne 'print "$2\t$1\n" if /^\s+TCP.*?([\w\.\*]+):(\d+)\s+0\.0\.0\.0:0/' |sort -n 
echo
echo "UDP ports"
echo "---------"
cat report.txt | grep "\*:\*" |
perl -ne 'print "$2\t$1\n" if /^\s+UDP\s+([\w\.]+):(\d+)\s+/' |sort -n