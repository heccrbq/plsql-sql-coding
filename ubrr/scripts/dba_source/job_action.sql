prompt
prompt <<<<<<<<<<<<<<< Job &1 >>>>>>>>>>>>>>>

set pagesize 6000 verify off feedback off heading off recsep off
spool '&1..SQL'
break on report

select job_action
  from DBA_SCHEDULER_JOBS where JOB_NAME = upper('&1')
;
quit
