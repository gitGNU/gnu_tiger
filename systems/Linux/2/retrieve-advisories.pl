#!/usr/bin/perl -n
# Run with:
# find . -name "*data" -exec cat \{\} \; | perl retrieve-advisories.pl >debian_advisories
# on the webml sources of Debian WWW to retrieve information
# on all advisories and output a database for use on Tiger checks.
# Writen for Debian's Tiger by Javier Fernández-Sanguino Peña
# Distributed under the GPL see www.gnu.org

#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2, or (at your option)
#    any later version.
#   
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#


$advisory=$1 if /pagetitle\>(.*?)\<\/define/ ;
$date=$1 if /date\>(.*?)\<\/define/ ;

if ( /\/([\w\-]+)\_([\.\d\-]+)\_(\w+)\.deb/ ) {
	$package=$1;
	$version=$2;
	$arch=$3;
	print "$package\t$version\t$arch\t$advisory\t$date\n";
}
