set tab off feedback off pagesize 0 linesize 2000 long 400000 longchunksize 2000 RECSEP OFF trimspool on VERIFY OFF TERMOUT OFF

spool '&1..sql'

select decode(LINE,1,'create or replace ','') || TEXT
from ALL_SOURCE
where NAME=upper('&1') and TYPE='PACKAGE'
order by LINE;

select decode(LINE,1,'create or replace ','') || TEXT
from ALL_SOURCE
where NAME=upper('&1') and TYPE='PACKAGE BODY'
order by LINE;

select 'create or replace view ' || VIEW_NAME || ' as', TEXT
from ALL_VIEWS
where VIEW_NAME=upper('&1');


quit
