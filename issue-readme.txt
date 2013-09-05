
WARNING BANNERS
---------------

The files "issue" and "issue.net" are *example* WARNING banner signs that can
be added to computer systems. The main difference between both is that the
second one does not provide any identificable information, to limit the
information exposed to external malicious users which could be used in 
socially-engineering attacks.

UNIX systems allow these warning sings to be added both for local users before
connecting (typically by configuring them in /etc/issue) or for remote
connections before a login attempt is made (typically in /etc/issue.net)

The warning banner might be required in some jurisdiction to notify users before
monitoring is done, even of malicious users. This is a complex subject,
as CISCO says:

	In some legal jurisdictions it can be impossible to prosecute and
	illegal to monitor malicious users unless they have been notified that 
	they are not permitted to use the system. One method to provide this
	notification is to place this information into a banner message that is
	configured (....)

	Legal notification requirements are complex, vary by jurisdiction and
	situation, and should be discussed with legal counsel. Even within
	jurisdictions, legal opinions can differ. 

TIGER can be configured to check if a give system is configured to produce
these signs. The script 'check_issue' takes care of this. For the script to work,
however, the system administrator must manually copy the issue (and issue.net)
file he wants to compare against in the Tiger installation directory.

As the configuration of these banners is a local decission and the wording 
depends on your legal requirements, TIGER does *not* setup a default banner
to compare with. If you want the check_issue script to work, please provide
a suitable file.


--------------------------------------------------------------------------

For more information, please read:

"Whitepaper: Login Warning Banners - A Discussion about Login/Warning Banners,
Their Emplacements and Their Uses" by Bob Radvanovsky, Unixworks
Available at http://www.unixworks.net/papers/wp-007.pdf

"Cisco Guide to Harden Cisco IOS Devices" - "Warning Banners" section.
Available at http://www.cisco.com/warp/public/707/21.html#warning

The following "login-banners" pen-test thread: http://seclists.org/pen-test/2003/Feb/129

