#!/usr/local/bin/perl -- # -*-Perl -*-
#
#  Scan .rhosts files for various things, including checks for
#  rhosting of other users.
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
#  Usage:  scan.rhosts
#
#----
# Where is the finger program?
$FINGER="/usr/ucb/finger";
#----
# How long do we give hosts to respond? (in seconds)
$ALARMTIME=30;

$SIG{'ALRM'} = 'sigalrm';

sub sigalrm {
    $timeout = 1;
    kill 9, $pid;
}

setpwent;

while(($user, $pwd, $uid, $gid, $quota, $comment, $gcos, $home) = getpwent){
    if(-f "$home/.rhosts"){
	$header = "$user ($gcos):";
	if((($d,$i,$mode) = stat(_))){
	    if($mode & 0066){
		$perms="";
		if($mode & 0060){
		    $perms .= " group";
		    $perms .= " readable" if($mode & 0040);
		    $perms .= " writable" if($mode & 0020);
		    $perms .= "," if($mode & 0006);
		}
		if($mode & 0006){
		    $perms .= " world";
		    $perms .= " readable" if($mode & 0004);
		    $perms .= " writable" if($mode & 0002);
		}
		print "$header .rhosts is$perms.\n";
	    }
	}
	else {
	    warn "stat($home/.rhosts): $!.\n";
	}
	
	open(RHOSTS, "$home/.rhosts") || warn "Can't open $home/.rhosts: $!\n";
	while(<RHOSTS>){
	    if(!/^\s*$/){
		($rhost, $ruser) = split;
		if($rhost eq "+" || $ruser eq "+"){
		    print "$header has + in ~/.rhosts\n";
		}
		elsif($rhost !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ &&
		      !(($s) = gethostbyname($rhost))){
		    print "$header $ruser@$rhost ([host unknown]).\n";
		}
		elsif($ruser ne "" && $ruser ne $user){
		    alarm($ALARMTIME);
		    $timeout = 0;
		    $foundit = 0;
		    $pid = open(FINGER, "$FINGER $ruser@$rhost 2>&1 |") || 
			warn "Can't execute $FINGER\n";
		    while(<FINGER>){
			alarm(0);
			if(/connect: *([^\r\n]*)\s$/){
			    $foundit = 1;
			    if($rhost =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/){
				print "$header (INVALID ENTRY) $ruser@$rhost ([$1]).\n";
			    }
			    else {
				print "$header $ruser@$rhost ([$1]).\n";
			    }
			}
			elsif(/^[Ll]og[oi]n.*:[ \t]+(\w+).+: *([^\r\n]*)\s*$/){
			    if($1 eq $ruser){
				$rname = $2;
				$foundit=1;
				if($rhost =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/){
				    print "$header (INVALID ENTRY) $ruser@$rhost ($rname).\n";
				}
				else {
				    print "$header $ruser@$rhost ($rname)\n";
				}
				last;
			    }
			}
		    }
		    alarm(0);
		    close(FINGER);
		    if($timeout){
			if($rhost =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/){
			    print "$header (INVALID ENTRY) $ruser@$rhost ($rname).\n";
			}
			else {
			    print "$header $ruser@$rhost ([timeout]).\n";
			}
		    }
		    elsif(!$foundit){
			if($rhost =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/){
			    print "$header (INVALID ENTRY) $ruser@$rhost ([no answer]).\n";
			}
			else {
			    print "$header $ruser@$rhost ([no answer]).\n";
			}
		    }
		}
	    }
	}
	close(RHOSTS);
    }
}
endpwent;
