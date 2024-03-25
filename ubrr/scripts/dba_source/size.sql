prompt
prompt <<<<<<<<<<<<<<< Object size &1 >>>>>>>>>>>>>>>

set pagesize 6000 verify off feedback off heading on recsep off

column area format 999,999,999,999
compute sum of owner object area on report
break on report

select substr(OWNER,1,20) owner,
       substr(SEGMENT_NAME,1,25) object,
       sum(BYTES) area
  from
       (
        select * from DBA_EXTENTS where SEGMENT_NAME like (upper('&1'))
        union
        select e.* from DBA_EXTENTS e,DBA_LOBS s
          where e.SEGMENT_NAME=s.SEGMENT_NAME and s.TABLE_NAME like (upper('&1')) and e.OWNER=s.OWNER and
                e.segment_type in ('LOBSEGMENT','LOB PARTITION','LOB SUBPARTITION')
       )
 group by owner,segment_name
 order by 1,3 desc,2;
quit
