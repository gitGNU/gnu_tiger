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

     Please see the file `COPYING' for the complete copyright notice.

 c/realpath.c - 06/14/93
 c/realpath.c - 04/22/2003 - jfs 
 	applied patch from Jeff Grub changing realpath
 	to my_realpath and adding upper bounds for buffers
	(libc already implements realpath, maybe it should be used if 
	available)

*/

#include <stdio.h>
#include <errno.h>
#include <sys/param.h>
#include <sys/types.h>
#include <string.h>
#ifndef MAXPATHLEN
#  ifdef        PATH_MAX
#    define MAXPATHLEN PATH_MAX
#  else /* PATH_MAX */
#    define MAXPATHLEN 1024
#  endif        /* PATH_MAX */
#endif  /* MAXPATHLEN */


/*
  Texas A&M University Supercomputer Center
  Douglas Lee Schales  4 November 1991

  realpath()

  This module returns a resolved pathname with all symbolic links
  and references to '..', '.' and extra '/' characters resolved.

  With '-d' flag, it decomposes a pathname into its "real" pieces.

*/
#ifdef NEEDGETWD
#define getwd getcwd
#endif

#ifdef __STDC__
extern char *getwd(char * const);
extern int readlink(char * const, char * const, const size_t);
extern char *my_realpath(const char *, char [], int);
extern char *_realpath(char [], int);
#else
extern char *getwd();
extern int readlink();
extern char *my_realpath();
extern char *_realpath();
#endif

#define ISDOT(x) ((*(x) == '.') && (*((x)+1) == '\0'))
#define ISDOTDOT(x) ((*(x) == '.') && (*((x)+1) == '.') && (*((x)+2) == '\0'))


/*
  Resolve 'path1', storing result in 'path2'.
*/

#ifdef __STDC__
char *
my_realpath(const char *path1, char path2[], int decomp)
#else
char *my_realpath(path1, path2, decomp)
char *path1, *path2;
int decomp;
#endif
{
     strcpy(path2, path1);
     return _realpath(path2, decomp);
}

/*
  Resolve 'path' in place.
*/

#ifdef __STDC__
char *
_realpath(char path[], int decomp)
#else
char *_realpath(path, decomp)
char *path;
int decomp;
#endif
{
     char *prevslash, *nextslash, *component;
     char buffer[MAXPATHLEN+1];
     char tmpbuf[MAXPATHLEN+1];
     int n, errcond, separator;
     char *bufp, *tbufp;
     char *rove, *scan;
     int linkcount = 0;

     if(path[0] != '/'){
	  getwd(buffer);
	  prevslash = buffer+strlen(buffer);
	  strcpy(prevslash,"/");
	  strcpy(prevslash+1,path);
	  bufp = buffer;
	  tbufp = path;
     }
     else {
	  bufp = path;
	  tbufp = buffer;
	  prevslash = bufp;
     }
     
     errcond = 0;
     
     while(!errcond && *prevslash){

	  while(*prevslash == '/' && *(prevslash+1) == '/'){
	       for(rove=prevslash+1;*rove;rove++)
		    *rove = *(rove+1);
	  }
	  component = prevslash+1;
	  for(rove = component;*rove && *rove != '/';rove++)
	       ;
	  nextslash = rove;
	  separator = *nextslash;
	  *nextslash = '\0';

	  if(ISDOT(component)){  /* Scrunch out "." */
	       *nextslash = separator;
	       for(scan=nextslash;*scan == '/';scan++)
		    ;
	       if(separator){
		    for(rove=component;*scan;)
			 *rove++ = *scan++;
		    *rove = '\0';
	       }
	       else
		    *component = '\0';
	  }
	  else if(ISDOTDOT(component)){ /* Handle ".." */
	       for(rove=prevslash-1;rove > bufp && *rove != '/';rove--)
		    ;
	       if(rove < bufp)
		    rove = bufp;
	       prevslash = rove++;
	       *nextslash = separator;
	       for(scan=nextslash;*scan == '/';scan++)
		    ;
	       while(*scan)
		    *rove++ = *scan++;
	       *rove = '\0';
	  }
	  else if((n = readlink(bufp, tbufp, MAXPATHLEN)) >= 0){
	       if(n > 0){
		    if(decomp){
			 char *cp;
			 if(prevslash != bufp){
			      for(cp=bufp;cp!=prevslash;cp++)
				   fputc(*cp, stdout);
			      fputc(' ', stdout);
			 }
		    }
		    linkcount++;
		    if(linkcount > 32)
			 errcond = 1;
		    else {
			 tbufp[n] = 0;
			 if(tbufp[0] == '/'){ /* Absolute link */
			      *nextslash = separator;
			      strcpy(tbufp+n, nextslash);
			      bufp = tbufp;
			      tbufp = (bufp == buffer) ? path : buffer;
			      prevslash = bufp;
			 }
			 else {  /* Relative link */
			      tbufp[n] = '\0';
			      *nextslash = separator;
			      if(separator){
				   strcpy(tmpbuf, nextslash);
				   for(rove=component, scan = tbufp;*scan;)
					*rove++ = *scan++;
				   for(scan=tmpbuf;*scan;)
					*rove++ = *scan++;
				   *rove = '\0';
			      }
			      else
				   strcpy(component, tbufp);
			 }
		    }
	       }
	  }
	  else { /* readlink() failed */
	       *nextslash = separator;
	       switch(errno){
	       case EINVAL:  /* Not a symbolic link */
		    prevslash = nextslash;
		    break;
	       case ENOENT:  /* No such file; ok if last component */
		    if(!separator){
			 prevslash = nextslash;
			 break;
		    }
		    /* Falls through if not last component */
	       default:      /* Error */
		    errcond = errno;
	       }
	  }
     }

     /* Get rid of trailing slash */
     n = strlen(bufp);
     if(n > 1 && bufp[n-1] == '/')
	  bufp[n-1] = '\0';

     /* Make sure final output is in 'path' */
     if(!errcond && bufp == buffer)
	  strcpy(path, buffer);
     else if(errcond)
	  path[0] = '\0';
	  
     return errcond ? (char *) 0 : path;
}

int
main(argc, argv)
int argc;
char **argv;
{
     char path[MAXPATHLEN+1];
     char rpath[MAXPATHLEN+1];
     int decomp = 0;

     char **argp = argv;

     if(argc > 1){
	  if(strcmp(argp[1], "-d") == 0){
	       decomp++;
	       argp++;
	       argc--;
	  }
     }

     if(argc == 1){
	  while(fgets(path, MAXPATHLEN, stdin)){
	       char *cp = strchr(path, '\n');
	       *cp = '\0';
	       my_realpath(path, rpath, decomp);
	       if(rpath[0])
		    fprintf(stdout, "%s %s\n", path, rpath);
	  }
     }
     else {
	  int i;
	  for(i=1;i<argc;i++){
	       my_realpath(argp[i], rpath, decomp);
	       if(rpath[0])
		    fprintf(stdout, "%s\n", rpath);
	  }
     }
     exit(0);
}
