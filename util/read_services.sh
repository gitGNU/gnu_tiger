#!/bin/sh
# Read a service file for a given system and generate a service
# file for use in Tiger
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

/bin/cat /etc/services | grep -v ^# | 
while read service type other other2
do
	[ ! -z "$service" ] && echo $service $type
done
