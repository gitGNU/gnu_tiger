#!/bin/sh
#
# Updates the information distributed by Tiger with the latest security
# advisories. Currently only works with Debian (DSAs) which are parsed
# from the WML sources (retrieved from CVS at DEB_ADV_DIR)
#
#     Copyright (C) 2002 Javier Fernandez-Sanguino
#
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
#     Please see the file `COPYING' for the complete copyright notice.


DEB_ADV_DIR=~jfs/debian/www/webwml/english/security/
if [ -d $DEB_ADV_DIR ] 
then
	find $DEB_ADV_DIR -name "*data" -exec cat \{\} \; | perl retrieve-advisories.pl >debian_advisories
else
	echo "Cannot access the $DEB_ADV_DIR directory."
	echo "Cannot generate the advisories data for Tiger."
	exit 1
fi

exit 0


