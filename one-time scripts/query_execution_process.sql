-- Головная и дочернии сессии
select
    s.*
from v$session s,
    v$px_session px
where px.qcsid(+) = s.sid 
    and px.qcserial#(+) = s.serial#
    and s.sid = 49 /*:p_sid*/;

-- Генерация undo
SELECT s.sid,
    s.serial#, 
    s.LOGON_TIME,
    s.STATUS,
    s.username, 
    s.OSUSER,
    tr.used_ublk undo_blocks,
    tr.USED_UREC/1024/1024 memory_mb,
    s.action
FROM gv$transaction tr, gv$session s
WHERE tr.addr = s.taddr
and s.sid = 440 /*:p_sid*/;
order by tr.USED_UBLK desc;

-- temp используемый сессией и параллелями к ней
SELECT S.SID
     , ROUND(sum(U.BLOCKS)*(select to_number(value) from v$parameter where name = 'db_block_size')/1024/1024,3) TEMP_USAGE
  FROM V$SESSION S,
    v$px_session px,
    V$SESSION spx,
       V$SORT_USAGE U
WHERE px.qcsid(+) = s.sid 
    and px.qcserial#(+) = s.serial#
    and spx.sid = px.sid
    and spx.serial# = px.serial#
    and S.SADDR = U.SESSION_ADDR
    and s.sid = 440 /*:p_sid*/
GROUP BY S.SID;

-- какие события происходили во время работы сессии
select * from v$session_event where sid = 49;

-- план запроса по sql_id сессии
select * from table(dbms_xplan.display_cursor('gctqtcg5tzrka'));

-- процесс выполнения запроса
select sid, 
    serial#,
    opname, 
    target, 
    sql_plan_operation, 
    sql_plan_options,
    (select s.event from v$session s where s.sid = sl.sid and s.serial# = sl.serial#) event,
    message, 
    sofar, 
    totalwork, 
    units,
    elapsed_seconds, 
    time_remaining, 
    sql_id,
    sql_plan_hash_value
from v$session_longops sl where sql_id = '29dqtsqw5mqz6';

-- SQL_PLAN + LONGOPS + EVENT
select 
    p.plan_hash_value,
    p.id,
    p.parent_id,
    lpad(' ', p.depth) || p.operation operation,
    p.options,
    p.object_owner,
    p.object_name,
    p.object_type,
    p.optimizer,
    p.cost,
    p.cardinality,
    p.bytes,
    p.cpu_cost,
    p.io_cost,
    p.time,
    p.access_predicates,
    p.filter_predicates,
    l.sid, 
    l.serial#,
    l.opname, 
    l.target, 
    l.sql_plan_operation, 
    l.sql_plan_options,
    (select s.event from v$session s where s.sid = l.sid and s.serial# = l.serial#) event,
    l.message, 
    l.sofar, 
    l.totalwork, 
    l.units,
    l.elapsed_seconds, 
    l.time_remaining,
    round(l.sofar / l.totalwork * 100, 2) || '%' progress
from v$session s,
    v$sql_plan p,
    v$session_longops l,
    v$session sl
where s.sql_id = p.sql_id
    and s.sql_hash_value = p.hash_value
    and s.sql_child_number = p.child_number
    and l.sql_id = p.sql_id
    and l.sql_plan_hash_value = p.plan_hash_value
    and s.sid = 297 /*:p_sid*/
order by plan_hash_value, id;



select * from v$sql_plan where sql_id in ('29dqtsqw5mqz6');
select * from v$session where sql_id = '29dqtsqw5mqz6';
select * from v$sql_plan;
select * from v$session where status = 'ACTIVE' and username is not null and sql_id <> '9vb2gx8hju3gw';
select * from v$session_longops;


                                   
SELECT "Query Plan", "Rows", "Rowsource Time(s)" FROM(
SELECT  LPAD('  ',4*(DEPTH-1))||operation||' '||options
   ||' '||object_name
   ||' '||DECODE(id, 0, 'Cost = '||position) "Query Plan",lpad(
                        CASE
                                WHEN cardinality > 1000000
                                THEN to_char(trunc(cardinality/1000000)) || 'M'
                                WHEN cardinality > 1000
                                THEN to_char(trunc(cardinality/1000)) || 'K'
                                ELSE cardinality || ' '
                        END
                ,       6
                ,       ' '
                ) AS "Rows",
    nvl(entries,0) as "Rowsource Time(s)"
   FROM gv$sql_plan sp,(select sql_id, sql_exec_id, sql_plan_line_id, sql_plan_hash_value, count(*) entries
from gv$active_session_history where sql_id = 'gctqtcg5tzrka'
and sql_exec_id = (select sql_exec_id from gv$active_session_history 
                    where sql_id =  'gctqtcg5tzrka' and rownum=1)
group by sql_id, sql_exec_id, sql_plan_line_id, sql_plan_hash_value
) ash
  WHERE sp.sql_id = 'gctqtcg5tzrka'
  AND ash.sql_id(+) = sp.sql_id
  AND ash.sql_plan_line_id(+)= sp.id
  ORDER by sp.plan_hash_value, sp.id
)
