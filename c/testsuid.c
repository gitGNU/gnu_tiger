/*

 tiger - A UN*X security checking system
 Copyright (C) 1993 Douglas Lee Schales, David K. Hess, David R. Safford


    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 1, or (at your option)
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    c/testsuid.c 
 */


int
main()
{
     int status = 0;
     setuid(1);
     if(
#ifdef HAVESETEUID
        seteuid(0) != -1 ||
#endif
#ifdef HAVESETRUID
        setruid(0) != -1 ||
#endif
	setuid(0) != -1)
        status = 1;
     exit(status);
}

