# Makefile for tiger binaries
# 
#
#     Makefile for tiger binaries - A UN*X security checking system
#     Copyright (C) 2002 Javier Fernandez-Sanguino Pen~a <jfs@computer.org>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 1, or (at your option)
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#     Please see the file `COPYING' for the complete copyright notice.
#

# For some reason snefru and md5 were received wrongly
# and they could not be compiled at first (they have
# been added later)
BINLIST=getpermit snefru md5 testsuid realpath
COPTS= -DNEEDGETWD

all: ${BINLIST}

install:  all
	cp ${BINLIST} ../bin/


% : %.c
	gcc ${COPTS} -o $@ $<

clean:
	-rm -f ${BINLIST}

distclean: clean
