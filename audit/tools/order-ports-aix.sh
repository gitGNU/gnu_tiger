#!/bin/sh
echo "TCP ports"
echo "---------"
cat netstat-an.out |grep "\*\.\*" |
perl -ne 'print "$2\t$1\n" if /^tcp.*?([\w\.\*]+)\.(\d+)\s+\*\.\*/' |sort -n 
echo "UDP ports"
echo "---------"
cat netstat-an.out  | grep "\*\.\*" |
perl -ne 'print "$2\t$1\n" if /^udp.*?([\w\.\*]+)\.(\d+)\s+/' |sort -n