#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <pwd.h>
#include <grp.h>
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

   c/getpermit.c 
*/
#ifdef __STDC__
void showperms(char *);
void putusrname(int);
void putgrpname(int);
#else
void showperms();
void putusrname();
void putgrpname();
#endif

#ifndef S_IRUSR
#define S_IRUSR 00400 
#endif

#ifndef S_IWUSR
#define S_IWUSR 00200
#endif

#ifndef S_IXUSR
#define S_IXUSR 00100
#endif

#ifndef S_IRGRP
#define S_IRGRP 00040
#endif

#ifndef S_IWGRP
#define S_IWGRP 00020
#endif

#ifndef S_IXGRP
#define S_IXGRP 00010
#endif

#ifndef S_IROTH
#define S_IROTH 00004
#endif

#ifndef S_IWOTH
#define S_IWOTH 00002
#endif

#ifndef S_IXOTH
#define S_IXOTH 00001
#endif

#ifndef S_ISUID
#define S_ISUID 04000
#endif

#ifndef S_ISGID
#define S_ISGID 02000
#endif

#ifndef S_ISVTX
#define S_ISVTX 01000
#endif


#ifdef __STDC__
int
main(int argc, char **argv)
#else
int main(argc, argv)
int argc;
char **argv;
#endif
{
     if(argc == 1){
	  char buf[1025];
	  
	  while(fgets(buf, 1024, stdin)){
	       buf[strlen(buf)-1] = 0;
	       showperms(buf);
	  }
     }
     else {
	  for(argv++;*argv;argv++)
	       showperms(*argv);
     }
}

#define outmode(m, b) {if((m)&(b))putchar('1');else putchar('0');putchar(' ');}

#ifdef __STDC__
void
showperms(char *fname)
#else
void
showperms(fname)
char *fname;
#endif
{
     struct stat sbuf;

     if(stat(fname, &sbuf) != -1){
	  fputs(fname, stdout);
	  putchar(' ');
	  putusrname(sbuf.st_uid);
	  putchar(' ');
	  putgrpname(sbuf.st_gid);
	  putchar(' ');

	  outmode(sbuf.st_mode, S_IRUSR);
	  outmode(sbuf.st_mode, S_IWUSR);
	  outmode(sbuf.st_mode, S_IXUSR);

	  outmode(sbuf.st_mode, S_IRGRP);
	  outmode(sbuf.st_mode, S_IWGRP);
	  outmode(sbuf.st_mode, S_IXGRP);

	  outmode(sbuf.st_mode, S_IROTH);
	  outmode(sbuf.st_mode, S_IWOTH);
	  outmode(sbuf.st_mode, S_IXOTH);

	  outmode(sbuf.st_mode, S_ISUID);
	  outmode(sbuf.st_mode, S_ISGID);
#ifdef S_ISVTX	  
	  outmode(sbuf.st_mode, S_ISVTX);
#else
	  putchar('0');
	  putchar(' ');
#endif
	  putchar('\n');
     }
     else {
	  perror(fname);
     }
}

struct gidcache {
     char *name;
     gid_t gid;
};

struct gidcache gcache[8192];

static int gc_init = 0;

#ifdef __STDC__
char *
cgetnamgid(int gid)
#else
char *
cgetnamgid(gid)
int gid;
#endif
{
     struct group *grent;
     int hash = gid & 8191;

     if(!gc_init){
	  (void)memset((void *)gcache, 0, sizeof(gcache));
	  gc_init = 1;
     }

     if(gcache[hash].name && gcache[hash].gid == gid){
	  return gcache[hash].name;
     }
     else if((grent = getgrgid(gid))){
	  if(!gcache[hash].name)
	       gcache[hash].name = (char *)malloc(9);
	  (void)strcpy(gcache[hash].name, grent->gr_name);
	  gcache[hash].gid = gid;
     }
     else {
	  if(!gcache[hash].name)
	       gcache[hash].name = (char *)malloc(9);
	  (void)sprintf(gcache[hash].name, "%8lu", (unsigned long)gid);
	  gcache[hash].gid = gid;
     }
     return gcache[hash].name;
}

struct uidcache {
     char *name;
     uid_t uid;
};

struct uidcache ucache[8192];

static int uc_init = 0;

#ifdef __STDC__
char *
cgetnamuid(int uid)
#else
char *
cgetnamuid(uid)
int uid;
#endif
{
     struct passwd *pwent;
     int hash = uid & 8191;

     if(!uc_init){
	  (void)memset((void *)ucache, 0, sizeof(ucache));
	  uc_init = 1;
     }

     if(ucache[hash].name && ucache[hash].uid == uid){
	  return ucache[hash].name;
     }
     else if((pwent = getpwuid(uid))){
	  if(!ucache[hash].name)
	       ucache[hash].name = (char *)malloc(9);
	  (void)strcpy(ucache[hash].name, pwent->pw_name);
	  ucache[hash].uid = uid;
     }
     else {
	  if(!ucache[hash].name)
	       ucache[hash].name = (char *)malloc(9);
	  (void)sprintf(ucache[hash].name, "%8lu", (unsigned long)uid);
	  ucache[hash].uid = uid;
     }
     return ucache[hash].name;
}

#ifdef __STDC__
void
putusrname(int uid)
#else
void
putusrname(uid)
int uid;
#endif
{
     fputs(cgetnamuid(uid), stdout);
}

#ifdef __STDC__
void
putgrpname(int gid)
#else
void
putgrpname(gid)
int gid;
#endif
{
     fputs(cgetnamgid(gid), stdout);
}
