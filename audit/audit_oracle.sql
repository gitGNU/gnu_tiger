# Oracle Audit Script v1.0 (c) 2001-2002 by Marc Heuse - marc@suse.de - License: GPL v2  - http://www.suse.de/~marc/audit/
# Use this script like this: connect internal; @audit_oracle.sql;
# This script was designed in a way to get all necessary data for a security review, however preventing doubles.
# Running this script costs pretty much performance, so execute it off-peak hours in a production environment!

# Increase the linesize to prevent line breaks
set linesize 1000 

# dump oracle parameters, remote_* + *os_auth* + audit_trail are important
spool parameter.log; 
show parameter; 
spool off; 

# dump all instances
spool v_instance.log; 
select instance_name, host_name, version, startup_time, status, archiver, database_status from v$instance; 
spool off; 

# dump all datafiles and their location
spool v_datafile.log; 
select file#, ts#, status, enabled, bytes, name, plugged_in from v$datafile; 
spool off; 

# dump log/redolog locations
spool v_logfile.log; 
select * from v$logfile; 
spool off; 

# dump all object privileges associated to users
spool privileges_objects.log; 
select u.username, r.granted_role, t.table_name, t.privilege, r.admin_option, r.default_role 
   from dba_tab_privs t, dba_role_privs r, dba_users u 
   where (t.grantee=r.granted_role AND r.grantee=u.username AND u.account_status='OPEN') 
   order by u.username, r.granted_role, t.privilege; 
spool off; 

# dump all system privileges associated to users
spool privileges_system.log; 
select u.username, r.granted_role, s.privilege, s.admin_option, r.default_role 
   from dba_sys_privs s, dba_role_privs r, dba_users u 
   where (s.grantee=r.granted_role AND r.grantee=u.username AND u.account_status='OPEN') 
   order by u.username, r.granted_role, s.privilege; 
spool off; 

# dump all role names, password protected?
spool dba_roles.log; 
select * from dba_roles; 
spool off; 

# dump object privileges for public
spool dba_tab_privs.log; 
select * from dba_tab_privs where grantee='PUBLIC'; 
spool off; 

# dump user data
spool dba_users.log; 
select * from dba_users; 
spool off; 

# dump user profiles for password/access management
spool dba_profiles.log; 
select * from dba_profiles order by profile; 
spool off; 

# try default accounts here:
# system: sys/change_on_install ; system/manager ; sap/sapr3
# examples: scott/tiger ; adams/wood ; blake/paper ; clark/cloth ; jones/steel
# for all others try same password as username
select username from dba_users; 
