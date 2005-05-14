#!/bin/sh
echo "TCP ports"
echo "---------"
cat netstat-an.out |grep "\*\.\*" |perl -ne 'print "$2\t$1\n" if /^\s*([\w\.\*+)\.(\d+)\s+\*\.\*/' |sort -n
echo
echo "UDP ports"
echo "---------"
cat netstat-an.out |grep -v "\*\.\*" | perl -ne 'print "$2\t$1\n" if /([\w\.\*]+)\.(\d+).*Idle/' |sort -n