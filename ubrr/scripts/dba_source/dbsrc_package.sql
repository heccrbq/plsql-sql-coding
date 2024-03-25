set tab off feedback off pagesize 0 linesize 2000 long 400000 longchunksize 2000 RECSEP OFF trimspool on VERIFY OFF TERMOUT OFF

spool 'PACKAGE_SPEC\&2..SQL'

select decode(LINE,1,'CREATE OR REPLACE ','') ||
       case when LINE = 1 then
        regexp_replace
        (
         case when instr(upper(TEXT),'"'||upper('&2')||'"') > 0 then replace(upper(TEXT),'"'||upper('&2')||'"','"'||owner||'".'||'"'||upper('&2')||'"')
         else replace(upper(TEXT),upper('&2'),'"'||owner||'"."'||upper('&2')||'"')
         end,
         '('||TYPE||')\s+(.*)','\1 \2',1,1,'i'
        )
       else TEXT
       end
from ALL_SOURCE
where NAME=upper('&2') and TYPE='PACKAGE' and owner=upper('&1')
order by LINE;

select '/' from dual
union
select 'show errors' from dual
;

spool 'PACKAGE_SPEC\login.sql'
select 'set define off' from dual;


spool 'PACKAGE_BODY\&2..SQL'

select decode(LINE,1,'CREATE OR REPLACE ','') ||
       case when LINE = 1 then
        regexp_replace
        (
         case when instr(upper(TEXT),'"'||upper('&2')||'"') > 0 then replace(upper(TEXT),'"'||upper('&2')||'"','"'||owner||'".'||'"'||upper('&2')||'"')
         else replace(upper(TEXT),upper('&2'),'"'||owner||'"."'||upper('&2')||'"')
         end,
         '('||TYPE||')\s+(.*)','\1 \2',1,1,'i'
        )
       else TEXT
       end
from ALL_SOURCE
where NAME=upper('&2') and TYPE='PACKAGE BODY' and owner=upper('&1')
order by LINE;

select '/' from dual
union
select 'show errors' from dual
;

spool 'PACKAGE_BODY\login.sql'
select 'set define off' from dual;

quit
