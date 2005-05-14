#!/bin/sh

cat systeminfo.txt |
perl -ne 'print $1."\n" if /\[\d+\]:\s+([Q|S|K]\w*\d+)\s+/'; 