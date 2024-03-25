select
    coalesce(event, 'ON CPU') event, count(1) event_count
from v$active_session_history where session_id = 10 and session_serial# = 963 group by event;

select sid,
    event, 
    total_waits, total_timeouts,
    time_waited, average_wait, max_wait, time_waited_micro,
    wait_class
from v$session_event 
where sid = 10-- userenv('sid')
;

select * from v$sql_monitor where sid = 10 and session_serial# = 963;


select sql_id,
    sum(tm_delta_cpu_time) cpu_time,
    sum(tm_delta_db_time) db_time,
    sum(delta_read_io_bytes) read_io_bytes,
    count(distinct sql_exec_id) sql_exec_id,
    count(nullif(in_connection_mgmt, 'N')) in_connection_mgmt,
    count(nullif(in_parse, 'N')) in_parse,
    count(nullif(in_hard_parse, 'N')) in_hard_parse,
    count(nullif(in_sql_execution, 'N')) in_sql_execution,
    count(nullif(in_plsql_execution, 'N')) in_plsql_execution,
    count(nullif(in_plsql_rpc, 'N')) in_plsql_rpc,
    count(nullif(in_plsql_compilation, 'N')) in_plsql_compilation,
    count(nullif(in_java_execution, 'N')) in_java_execution,
    count(nullif(in_bind, 'N')) in_bind,
    count(nullif(in_cursor_close, 'N')) in_cursor_close,
    count(nullif(in_sequence_load, 'N')) in_sequence_load,
    count(nullif(in_tablespace_encryption, 'N')) in_tablespace_encryption
from v$active_session_history where session_id = 10 and session_serial# = 963 group by sql_id;



with source as (
    select 10 sid, 963 serial#, to_date('27.06.2022 13:24:46', 'dd.mm.yyyy hh24:mi:ss') exec_s from v$session where sid = userenv('sid')),
sbq as (
    select /*+no_merge*/ 
        sql_id, sql_exec_id, sql_child_number, sql_plan_hash_value, count(1) rowcount 
    from v$active_session_history ash
        join source s on s.sid = ash.session_id and s.serial# = ash.session_serial#
--    where sample_time >= s.exec_date
    group by sql_id, sql_exec_id, sql_child_number, sql_plan_hash_value)

select sbq.*, 
    (select object_name || ' (' || lower(object_type) || ')' from user_objects where object_id = s.program_id) object_name,
    s.program_line#,
    s.* 
from sbq, v$sql s 
where sbq.sql_id = s.sql_id(+) and sbq.sql_child_number = s.child_number(+) and sbq.sql_plan_hash_value = s.plan_hash_value(+)
order by rowcount desc;



select ss.sid, ss.statistic#, st.name, ss.value 
from v$sesstat ss, v$statname st
where ss.statistic# = st.statistic# 
    and sid = 10-- userenv('sid') 
    and st.name in ('recursive calls', 
                    -- 
                    'session logical reads', 'CPU used by this session', 'DB time', 'user I/O wait time', 'session pga memory max', 'session uga memory max',
                    'physical read total bytes',
                    --
                    'db block gets', 'db block gets direct', 'db block gets from cache', 'db block gets from cache (fastpath)', 'db block changes',                    
                    'consistent gets', 'consistent gets direct', 'consistent gets examination', 'consistent gets examination (fastpath)', 'consistent gets from cache', 'consistent gets pin', 'consistent gets pin (fastpath)',
                    'physical reads', 'physical reads cache', 'physical reads cache prefetch', 'physical reads direct', 'physical reads direct (lob)', 'physical reads direct temporary tablespace',
                    'redo size',
                    'bytes sent via SQL*Net to client',
                    'bytes received via SQL*Net from client',
                    'sorts (memory)', 'sorts (rows)',
                    'rows fetched via callback',
                    'undo change vector size',
                    'parse count (failures)', 'parse count (hard)', 'parse count (total)', 'parse time cpu', 'parse time elapsed',
                    'Workload Capture: PL/SQL user subcalls', 'Workload Capture: PL/SQL user calls', 'Workload Capture: PL/SQL subcall size of recording', 'Workload Capture: PL/SQL dbtime',
                    'Workload Replay: PL/SQL user calls', 'Workload Replay: PL/SQL user subcalls', 'Workload Replay: PL/SQL dbtime');



select stat_name, value 
from v$sess_time_model 
where sid = 10
    and stat_name in ('DB CPU', 
                      'DB time', 
                      'Java execution elapsed time', 
                      'PL/SQL compilation elapsed time',
                      'PL/SQL execution elapsed time',
                      'background cpu time',
                      'background elapsed time',
                      'hard parse (bind mismatch) elapsed time',
                      'hard parse (sharing criteria) elapsed time',
                      'hard parse elapsed time',
                      'parse time elapsed',
                      'sql execute elapsed time' );                                                     


select * From v$sess_io where sid = 10;

select ss.sid, st.name, ss.value 
from v$sesstat ss, v$statname st
where ss.statistic# = st.statistic# 
    and sid = 10-- userenv('sid') 
    and st.name in ('db block gets', 'consistent gets', 'physical reads', 'db block changes', 'consistent changes');
                    
