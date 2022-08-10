select
    s.type,
    s.username,
    t.sid,
    s.serial#,
    s.sql_id,
    s.event,
    sum(t.value) as "LOGICAL READS (buffers)",
    round((ratio_to_report(sum(t.value)) over ())*100, 2) as "pct, %",
    io.block_gets,
    io.consistent_gets,
    io.physical_reads,
    io.block_changes,
    io.consistent_changes,
    o.object_name,
    sql.program_line#
--    sql.sql_fulltext
from v$session s
    join v$sesstat t on t.sid = s.sid
    join v$statname n on n.statistic# = t.statistic#
    join v$sess_io io on io.sid = s.sid
    left join v$sql sql on sql.sql_id = s.sql_id and sql.child_number = s.sql_child_number
    left join dba_objects o on o.object_id = sql.program_id
where s.status = 'ACTIVE'
    and n.name like '%session logical reads%'
    and s.username is not null
group by s.type, 
    s.username,
    t.sid,
    s.serial#,    
    s.sql_id,
    s.event,
    io.block_gets,
    io.consistent_gets,
    io.physical_reads,
    io.block_changes,
    io.consistent_changes,
    o.object_name,
    sql.program_line#
--    sql.sql_fulltext
order by 7 desc;
