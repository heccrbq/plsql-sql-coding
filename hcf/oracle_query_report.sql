select dbid, db_unique_name, platform_name, log_mode, open_mode from gv$database db, gv$sql s where db.inst_id = s.inst_id and s.sql_id = :sqlid and s.plan_hash_value = :hv and s.child_number = :cn;
--select dbid, db_unique_name, platform_name, log_mode, open_mode from gv$database db, gv$sql s where db.inst_id = s.inst_id and s.sql_id = 'dgsa8dmtj0b75' and s.plan_hash_value = 307938658 and s.child_number = 0;

select instance_number, instance_name, version, host_name, startup_time from gv$instance i, gv$sql s where i.inst_id = s.inst_id and s.sql_id = :sqlid and s.plan_hash_value = :hv and s.sql_child_number = :cn;
--select instance_number, instance_name, version, host_name, startup_time from gv$instance i, gv$sql s where i.inst_id = s.inst_id and s.sql_id = 'dgsa8dmtj0b75' and s.plan_hash_value = 307938658 and s.child_number = 0;

-- version
select * from gv$version;

-- TNS address

select 
    s.sql_id, s.plan_hash_value, s.child_number, 
	s.loaded_versions, s.first_load_time, s.invalidations, s.is_reoptimizable,
    round(s.elapsed_time / 1e6, 4) elapsed_time_sec,
	round(s.cpu_time / 1e6, 4) cpu_time_sec, 
	round(ss.avg_hard_parse_time / 1e6, 4) avg_hard_parse_time_sec, 
	round(s.concurrency_wait_time / 1e6, 4) concurrency_wait_time_sec, 
	round(s.user_io_wait_time / 1e6, 4) user_io_wait_time_sec, s.application_wait_time,
    s.disk_reads, s.buffer_gets, s.direct_writes, s.direct_reads, 
    s.rows_processed, s.fetches, s.end_of_fetch_count,
    s.executions, s.parse_calls, s.px_servers_executions, 
    s.program_id, s.program_line# 
from v$sql s,
    v$sqlstats ss
where s.sql_id = '3bx5bxj2b4s4a'/*:sql_id*/
--	and s.plan_hash_value = 3682407720/*:sql_plan_hash_value*/
--	and s.child_number = 3/*:sql_child_number*/
    and s.sql_id = ss.sql_id(+)
    and s.plan_hash_value = ss.plan_hash_value(+);

-- Статистика работы запроса за 30 дней с группировкой по дням
select 
    s.sql_id AS sqlid,	
    s.plan_hash_value hv,
--    (select t.sql_text from dba_hist_sqltext t where s.sql_id = t.sql_id) AS text,
    nvl(trunc(w.begin_interval_time), w.begin_interval_time) AS tl,
    sum(s.executions_delta) AS e,
    round(sum(s.elapsed_time_delta)     / greatest(sum(s.executions_delta), 1) / 1e6, 2) AS ela,
    round(sum(s.cpu_time_delta)         / greatest(sum(s.executions_delta), 1) / 1e6, 2) AS cpu,
    round(sum(s.iowait_delta)           / greatest(sum(s.executions_delta), 1) / 1e6, 2) AS io,
    round(sum(s.disk_reads_delta)       / greatest(sum(s.executions_delta), 1)) AS disk,
    round(sum(s.buffer_gets_delta)      / greatest(sum(s.executions_delta), 1)) AS lio,
    round(sum(s.rows_processed_delta)   / greatest(sum(s.executions_delta), 1)) AS r,
    round(sum(s.ccwait_delta)           / greatest(sum(s.executions_delta), 1) / 1e6, 2) AS cc,
    round(sum(s.apwait_delta)           / greatest(sum(s.executions_delta), 1) / 1e6, 2) AS app,
    round(sum(s.plsexec_time_delta)     / greatest(sum(s.executions_delta), 1) / 1e6, 2) AS plsql,
    round(sum(s.javexec_time_delta)     / greatest(sum(s.executions_delta), 1) / 1e6, 2) AS java,
    round(sum(s.parse_calls_delta)      / greatest(sum(s.executions_delta), 1)) AS pc,
    round(sum(s.px_servers_execs_delta) / greatest(sum(s.executions_delta), 1)) AS px
from dba_hist_sqlstat s,
    dba_hist_snapshot w
where s.snap_id = w.snap_id
    and s.instance_number = w.instance_number
    and s.sql_id = '9gnd89xzawftt' /*:sql_id*/
    and w.begin_interval_time >= trunc(sysdate) - 7
    and w.begin_interval_time <= trunc(sysdate) + 1
group by grouping sets ((trunc(w.begin_interval_time),
    s.sql_id
    ,s.plan_hash_value),
    (w.begin_interval_time, s.sql_id, s.plan_hash_value))
order by tl desc;

-- Общая статистика за все запуски, пока запрос живет в shared pool
select 
    s.sql_id sqlid,
    s.plan_hash_value hv,
    s.child_number cn,
    to_date(s.last_load_time, 'yyyy-mm-dd/hh24:mi:ss') tl,
    s.executions e,
    round(s.elapsed_time          / greatest(s.executions, 1) / 1e6, 4) ela,
    round(s.cpu_time              / greatest(s.executions, 1) / 1e6, 4) cpu,
    round(s.user_io_wait_time     / greatest(s.executions, 1) / 1e6, 4) io,
    round(ss.avg_hard_parse_time  / greatest(ss.executions, 1) / 1e6, 4) hp,
    round(s.disk_reads            / greatest(s.executions, 1)) disk,
    round(s.buffer_gets           / greatest(s.executions, 1)) lio,
    round(s.rows_processed        / greatest(s.executions, 1)) r,
    round(s.concurrency_wait_time / greatest(s.executions, 1) / 1e6, 4) cc,
    round(s.application_wait_time / greatest(s.executions, 1) / 1e6, 4) app,
    round(s.plsql_exec_time       / greatest(s.executions, 1) / 1e6, 4) plsql,
    round(s.java_exec_time        / greatest(s.executions, 1) / 1e6, 4) java,
    round(s.parse_calls           / greatest(s.executions, 1)) pc,
    round(s.px_servers_executions / greatest(s.executions, 1)) px
from gv$sql s,
    gv$sqlstats ss
where s.sql_id = 'dgsa8dmtj0b75'
    and s.sql_id = ss.sql_id(+)
    and s.inst_id = ss.inst_id (+)
    and s.plan_hash_value = ss.plan_hash_value(+);

-- Последний запуск
select 
    s.sql_id sqlid,
    s.plan_hash_value hv,
    s.child_number cn,
    to_date(s.last_load_time, 'yyyy-mm-dd/hh24:mi:ss') tl,
    ss.delta_execution_count e,
    round(ss.delta_elapsed_time          / greatest(ss.delta_execution_count, 1) / 1e6, 4) ela,
    round(ss.delta_cpu_time              / greatest(ss.delta_execution_count, 1) / 1e6, 4) cpu,
    round(ss.delta_user_io_wait_time     / greatest(ss.delta_execution_count, 1) / 1e6, 4) io,
    round(ss.avg_hard_parse_time         / greatest(ss.executions, 1) / 1e6, 4) hp,
    round(ss.delta_disk_reads            / greatest(ss.delta_execution_count, 1)) disk,
    round(ss.delta_buffer_gets           / greatest(ss.delta_execution_count, 1)) lio,
    round(ss.delta_rows_processed        / greatest(ss.delta_execution_count, 1)) r,
    round(ss.delta_concurrency_time      / greatest(ss.delta_execution_count, 1) / 1e6, 4) cc,
    round(ss.delta_application_wait_time / greatest(ss.delta_execution_count, 1) / 1e6, 4) app,
    round(ss.delta_plsql_exec_time       / greatest(ss.delta_execution_count, 1) / 1e6, 4) plsql,
    round(ss.delta_java_exec_time        / greatest(ss.delta_execution_count, 1) / 1e6, 4) java,
    round(ss.delta_parse_calls           / greatest(ss.delta_execution_count, 1)) pc,
    round(ss.delta_px_servers_executions / greatest(ss.delta_execution_count, 1)) px
from v$sql s,
    v$sqlstats ss
where s.sql_id = '3bx5bxj2b4s4a'
    and s.sql_id = ss.sql_id(+)
    and s.plan_hash_value = ss.plan_hash_value(+);
