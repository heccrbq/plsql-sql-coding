разница между loop return и rownum

drop table dropme;
create table dropme as select level id from dual connect by level <= 1e3;

drop table dropme2;
create table dropme2 as select mod(id,5) id from dropme;

exec dbms_stats.gather_table_stats(user,'dropme');
exec dbms_stats.gather_table_stats(user,'dropme2');

declare 
    n number;
    function f return number is
    begin
        for i in(select --+ gather_plan_statistics
            * from dropme d
            where exists (select 0 from dropme2 d2 where d.id = d2.id))
            loop
                return 1;
            end loop;
        return 0;
    end;
begin
    n := f;
end;
/

declare 
    n number;
    function f return number is
        r number;
    begin
        select --+ gather_plan_statistics
            1
            into r
            from dropme d
            where exists (select 0 from dropme2 d2 where d.id = d2.id)
            and rownum = 1;
        return n;
        exception 
        when no_data_found then return 0;
    end;
begin
    n := f;
end;
/



select sql_id, plan_hash_value, child_number, sql_text from v$sql where sql_fulltext like '%gather_plan_statistics%' and sql_fulltext not like '%v$sql%';
select * from table(dbms_xplan.display_cursor(sql_id => '3hm92ufywtq31'/*:sql_id*/, cursor_child_no => 0/*:sql_child_number*/, format => 'ALLSTATS LAST'));

select ss.sid, ss.statistic#, st.name, ss.value 
from v$sesstat ss, v$statname st
where ss.statistic# = st.statistic# 
    and sid = userenv('sid') 
    and lower(st.name) = 'CPU used by this session';












drop table dropme;
create table dropme(id number, event_time date, status number);
create index dropme_idx on dropme(id, event_time);

insert into dropme select round(dbms_random.value(1,3)), sysdate+dbms_random.value(0,100), round(dbms_random.value(0,1)) from dual connect by level <= 1e5;
commit;

select max(event_time) from dropme;

alter system flush buffer_cache;

select -- abrakadabra6
       --+ gather_plan_statistics
    status From dropme where event_time in (
select max(event_time) from dropme where id = 1 and event_time <= to_date('2021-09-10 11:37:00', 'yyyy-mm-dd hh24:mi:ss')) and id = 1;

select -- abrakadabra7
       --+ gather_plan_statistics
    max(status)keep(dense_rank last order by event_time)
from dropme where id = 1 and event_time <= to_date('2021-09-10 11:37:00', 'yyyy-mm-dd hh24:mi:ss');

select sql_id, plan_hash_value, child_number, sql_text from v$sql where sql_fulltext like '%abrakadabra7%' and sql_fulltext not like '%v$sql%';
select * from table(dbms_xplan.display_cursor(sql_id => '4ykcytd2mhh14'/*:sql_id*/, cursor_child_no => 0/*:sql_child_number*/, format => 'ALLSTATS LAST'));







Plan hash value: 1285018707
 
---------------------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name       | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  |
---------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |            |      1 |        |      1 |00:00:00.01 |       5 |      2 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| DROPME     |      1 |      1 |      1 |00:00:00.01 |       5 |      2 |
|*  2 |   INDEX RANGE SCAN                  | DROPME_IDX |      1 |      1 |      1 |00:00:00.01 |       4 |      1 |
|   3 |    SORT AGGREGATE                   |            |      1 |      1 |      1 |00:00:00.01 |       2 |      1 |
|   4 |     FIRST ROW                       |            |      1 |      1 |      1 |00:00:00.01 |       2 |      1 |
|*  5 |      INDEX RANGE SCAN (MIN/MAX)     | DROPME_IDX |      1 |      1 |      1 |00:00:00.01 |       2 |      1 |
---------------------------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("ID"=1 AND "EVENT_TIME"=)
   5 - access("ID"=1 AND "EVENT_TIME"<=TO_DATE(' 2021-09-10 11:37:00', 'syyyy-mm-dd hh24:mi:ss'))
   
   
   
   
   
   
   
   
   
   
   
   
Plan hash value: 1470085436
 
------------------------------------------------------------------------------------------------
| Id  | Operation          | Name   | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  |
------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |        |      1 |        |      1 |00:00:00.10 |     308 |    119 |
|   1 |  SORT AGGREGATE    |        |      1 |      1 |      1 |00:00:00.10 |     308 |    119 |
|*  2 |   TABLE ACCESS FULL| DROPME |      1 |  20447 |  24655 |00:00:00.01 |     308 |    119 |
------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - filter(("ID"=1 AND "EVENT_TIME"<=TO_DATE(' 2021-09-10 11:37:00', 'syyyy-mm-dd 
              hh24:mi:ss')))
			  
			  
			  
			  
			  
			  
			  
Plan hash value: 1187981288
 
----------------------------------------------------------------------------------------------------------------------
| Id  | Operation                            | Name       | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  |
----------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                     |            |      1 |        |      1 |00:00:00.01 |     928 |     91 |
|   1 |  SORT AGGREGATE                      |            |      1 |      1 |      1 |00:00:00.01 |     928 |     91 |
|   2 |   TABLE ACCESS BY INDEX ROWID BATCHED| DROPME     |      1 |   1015 |   1015 |00:00:00.02 |     928 |     91 |
|*  3 |    INDEX RANGE SCAN                  | DROPME_IDX |      1 |   1015 |   1015 |00:00:00.01 |       5 |      0 |
----------------------------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   3 - access("ID"=1 AND "EVENT_TIME"<=TO_DATE(' 2021-06-21 10:00:00', 'syyyy-mm-dd hh24:mi:ss'))
