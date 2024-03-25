https://github.com/abdulirfan3/Oracle_SQL_Scripts/blob/master/capture_awr_stats_mini_awr.sql

https://github.com/iusoltsev/sqlplus/blob/master/dba_hist_system_event.sql


with source as (
    select '6hjs0624rwqyy' sql_id, trunc(sysdate) - 30 btime, trunc(sysdate) + 1 etime from dual
 )
select 
--    (select trim(dbms_lob.substr(t.sql_text, 4000)) from dba_hist_sqltext t where s.sql_id = t.sql_id) AS text,
--    s.sql_id AS sqlid,
    s.plan_hash_value hv,
    trunc(w.begin_interval_time) AS tl,
    sum(s.executions_delta) AS e,
    round(sum(s.elapsed_time_delta)     / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS ela,
    round(sum(s.cpu_time_delta)         / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS cpu,
    round(sum(s.iowait_delta)           / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS io,
    round(sum(s.ccwait_delta)           / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS cc,
    round(sum(s.apwait_delta)           / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS app,
    round(sum(s.plsexec_time_delta)     / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS plsql,
    round(sum(s.javexec_time_delta)     / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS java,
    round(sum(s.disk_reads_delta)       / greatest(sum(s.executions_delta), 1)) AS disk,
    round(sum(s.buffer_gets_delta)      / greatest(sum(s.executions_delta), 1)) AS lio,
    round(sum(s.rows_processed_delta)   / greatest(sum(s.executions_delta), 1)) AS r,
    round(sum(s.parse_calls_delta)      / greatest(sum(s.executions_delta), 1)) AS pc,
    round(sum(s.px_servers_execs_delta) / greatest(sum(s.executions_delta), 1)) AS px
from dba_hist_sqlstat s,
    dba_hist_snapshot w,
    source src
where s.snap_id = w.snap_id
    and s.instance_number = w.instance_number
    and s.sql_id = src.sql_id
    and w.begin_interval_time between src.btime and src.etime
group by trunc(w.begin_interval_time),
    s.sql_id
    ,s.plan_hash_value
order by tl desc;


with source as (
    select '6hjs0624rwqyy' sql_id, date'2023-03-01' btime, date'2023-03-02' etime from dual
 )
select 
    ash.session_id || ',' || ash.session_serial# sid_serial, 
    ash.sql_exec_id, 
    ash.sql_plan_hash_value plan_hash_value,
    min(w.snap_id) || ' - ' || max(w.snap_id) snap_range,
    ash.sql_exec_start, 
    cast(max(ash.sample_time) as date) sql_exec_stop, 
--    round((cast(max(ash.sample_time) as date) - ash.sql_exec_start) * 86400) sql_exec_diff,
    round(sum(ash.tm_delta_db_time)/1e6, 2) db_time, 
    round(sum(ash.tm_delta_cpu_time)/1e6, 2) cpu_time, 
    round(sum(ash.delta_read_io_bytes)/1024/1024) read,
    round(sum(ash.delta_write_io_bytes)/1024/1024) write,
    -- in flags --
    count(1) wait_count,
    count(nullif(ash.in_parse, 'N')) parse,
    count(nullif(ash.in_hard_parse, 'N')) hard_parse,
    count(nullif(ash.in_sql_execution, 'N')) sql,
    count(nullif(ash.in_plsql_execution, 'N')) plsql,
    count(nullif(ash.in_java_execution, 'N')) java,
    count(nullif(ash.in_cursor_close, 'N')) cursor_close
from source s
    join dba_hist_active_sess_history ash on ash.sql_id = s.sql_id
    join dba_hist_snapshot w on w.instance_number = ash.instance_number
                            and w.dbid = ash.dbid
                            and w.snap_id = ash.snap_id
                            and w.begin_interval_time between s.btime and s.etime
group by ash.session_id,
    ash.session_serial#,
    ash.sql_exec_id,
    ash.sql_exec_start,
    ash.sql_plan_hash_value
order by sql_exec_start desc nulls last;


with source as (
    select 7372 sid, 21398 serial#, 110349 bsnap_id, 110354 esnap_id from dual),
sbq as (
    select /*+no_merge*/
        sql_id, count(distinct sql_exec_id || to_char(sql_exec_start, 'yyyymmddhh24:mi:ss')) unq_run, count(1) rowcount,
        round(sum(tm_delta_db_time)/1e6, 2) db_time, round(sum(tm_delta_cpu_time)/1e6, 2) cpu_time
    from dba_hist_active_sess_history ash
        join source s on s.sid = ash.session_id and s.serial# = ash.session_serial#
--    where snap_id between s.bsnap_id and s.esnap_id
    group by sql_id
)

select sbq.*, 
    s.sql_text
from sbq, dba_hist_sqltext s
where sbq.sql_id = s.sql_id(+)
order by rowcount desc;


with source as 
(
    select '6hjs0624rwqyy' sql_id, 1818152427 plan_hash_value, 16777216 sql_exec_id, 110349 snap_id_from, 110354 snap_id_to from dual
),
settings as 
(
    select 1 enable_events from dual
),
ash as
(   -- строки с sql_exec_id is null and in_parse = 'Y' and in_hard_parse = 'Y' учтены в ASH: parse - в это время происходит парсинг запроса.
    select /*+materialize*/
        ash.*
    from dba_hist_active_sess_history ash
		join source s on ash.sql_id = s.sql_id 
					 and ash.sql_plan_hash_value = s.plan_hash_value 
					 and ash.sql_exec_id = s.sql_exec_id
					 and ash.snap_id between s.snap_id_from and s.snap_id_to
)

-- Статистика выполнения запроса по sql_id и plan_hash_value из dba_hist_sqlstat
select
    null id,
    null parent_id,
    null depth,
    'SQLSTAT: ' ||
    'SQL_ID = ' || st.sql_id || 
    ', hv = '   || st.plan_hash_value ||
    ', e = '    || sum(st.executions_delta) || 
    ', ela = '  || to_char(round(sum(st.elapsed_time_delta) / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') || 
    ', cpu = '  || to_char(round(sum(st.cpu_time_delta)     / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') || 
    ', io = '   || to_char(round(sum(st.iowait_delta)       / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', disk = ' || round(sum(st.disk_reads_delta)           / greatest(sum(st.executions_delta), 1)) ||
    ', lio = '  || round(sum(st.buffer_gets_delta)          / greatest(sum(st.executions_delta), 1)) || 
    ', r = '    || round(sum(st.rows_processed_delta)       / greatest(sum(st.executions_delta), 1)) ||
    ', px = '   || round(sum(st.px_servers_execs_delta)     / greatest(sum(st.executions_delta), 1)) sqlplan,
    null ash_count,
    to_char(round(sum(st.elapsed_time_delta) / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ela,
    null db_time,
    to_char(round(sum(st.cpu_time_delta)     / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') cpu_time,
    null px,
    null tmp,
    null pga,
    null undo,
    null hist
from dba_hist_sqlstat st
where (st.sql_id, st.plan_hash_value) in (select sql_id, plan_hash_value from source)
    and (st.instance_number, st.snap_id) in 
        (select 
            s.instance_number, s.snap_id 
        from dba_hist_snapshot s 
        where s.snap_id in 
            (select /*+no_merge */ distinct ash.snap_id from ash))
group by st.sql_id, st.plan_hash_value
union all
-- Статистика конкретного SQL_EXEC_ID в разрезе точечных snap_id
select
    null id,
    null parent_id,
    null depth,
    'ASH: ' ||
    'SQL_EXEC_ID = ' || ash.sql_exec_id ||
    ', from = ' || ash.sql_exec_start ||
    ', parse = ' || 
        to_char(
            round(
                (select 
                    sum(h.tm_delta_time) / 1e6
                from dba_hist_active_sess_history h 
                where h.sql_id = ash.sql_id and h.sql_plan_hash_value = ash.sql_plan_hash_value and h.session_id = ash.session_id and h.session_serial# = ash.session_serial#
                    -- нужен between между snap_id_from и snap_id_to
					and h.snap_id = (select min(ash.snap_id) from ash)
                    and h.in_parse = 'Y' and h.in_hard_parse = 'Y')
            , 2)
        , 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', ela = '  || to_char(round(sum(ash.tm_delta_time)     / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', db = '  || to_char(round(sum(ash.tm_delta_db_time)  / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', cpu = ' || to_char(round(sum(ash.tm_delta_cpu_time) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', waiting (%) = '  || to_char(round(count(decode(ash.session_state, 'WAITING', 1)) / count(1) * 100, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', on cpu (%) = '  || to_char(round(count(decode(ash.session_state, 'ON CPU', 1)) / count(1) * 100, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') sqlplan,
    count(1) ash_count,
    to_char(round(sum(ash.tm_delta_time)     / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ela,
    to_char(round(sum(ash.tm_delta_db_time)  / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') db_time,
    to_char(round(sum(ash.tm_delta_cpu_time) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') cpu_time,
    null px,
    null tmp,
    null pga,
    count((select df.relative_fno from dba_data_files df join dba_tablespaces dt on df.tablespace_name = dt.tablespace_name where dt.contents = 'UNDO' and df.relative_fno = ash.current_file#)) undo,
    null hist
from ash
group by ash.sql_id, ash.sql_plan_hash_value, ash.sql_exec_id, ash.sql_exec_start, ash.session_id, ash.session_serial#
union all
select
    sp.id, sp.parent_id, nullif(sp.depth - 1, -1) depth, 
    lpad(' ', 4*depth) || sp.operation || nvl2(sp.optimizer, '  Optimizer=' || sp.optimizer, null) ||
    nvl2(sp.options, ' (' || sp.options || ')', null) || 
    nvl2(sp.object_name, ' OF ''' || nvl2(sp.object_owner, sp.object_owner || '.', null) || sp.object_name || '''', null) ||
    decode(sp.object_type, 'INDEX (UNIQUE)', ' (UNIQUE)') ||
    '  (Cost=' || cost || ' Card=' || sp.cardinality || ' Bytes=' || bytes || ')' sqlplan,
    ash.ash_count,
    to_char(round(ash.tm_time  / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ela,
    to_char(round(ash.db_time  / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') db_time,
    to_char(round(ash.cpu_time / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') cpu_time,
    ash.px,
    ash.tmp,
    ash.pga,
    ash.undo,
    to_char(round(100 * ratio_to_report(ash.db_time)over(), 2), 'fm00D00', 'nls_numeric_characters = ''.,') ||
        case when ash.db_time is not null then
            '%(cpu ' || to_char(round(100 * ash.cpu_time/ash.db_time, 2), 'fm00D00', 'nls_numeric_characters = ''.,') || '%' ||
            ' wait ' || to_char(round(100 * (ash.db_time - ash.cpu_time)/ash.db_time, 2), 'fm00D00', 'nls_numeric_characters = ''.,') || '%)'
        end  ||
        case when ratio_to_report(ash.db_time)over() >= 0.005 then rpad(' ', 1 + round(100 * ratio_to_report(ash.db_time)over()), '*') end hist
from dba_hist_sql_plan sp
    left join
        (select /*+*no_merge*/
            ash.sql_id,
            ash.sql_plan_hash_value,
            ash.sql_plan_line_id,
            count(1) ash_count,
            sum(ash.tm_delta_time) tm_time,
            sum(ash.tm_delta_db_time) db_time,
            sum(ash.tm_delta_cpu_time) cpu_time,
            count(distinct qc_session_id) px,
            round(max(temp_space_allocated)/1024/1024, 3) tmp,
            round(max(pga_allocated)/1024/1024, 3) pga,
            count((select df.relative_fno from dba_data_files df join dba_tablespaces dt on df.tablespace_name = dt.tablespace_name where dt.contents = 'UNDO' and df.relative_fno = ash.current_file#)) undo
        from ash
        group by ash.sql_id,
            ash.sql_plan_hash_value,
            ash.sql_plan_line_id) ash 
    on ash.sql_id = sp.sql_id
        and ash.sql_plan_hash_value = sp.plan_hash_value
        and ash.sql_plan_line_id = sp.id
where (sp.sql_id, sp.plan_hash_value) in (select sql_id, plan_hash_value from source)
union all
select
    ash.sql_plan_line_id id,
    null parent_id,
    null depth,
    lpad('| ', 2 + (select 4*(sp.depth+1) from dba_hist_sql_plan sp where sp.sql_id = ash.sql_id and sp.plan_hash_value = ash.sql_plan_hash_value and sp.id = ash.sql_plan_line_id)) || 
    rpad(lower(ash.session_state), 7) || ' | ' ||  
    rpad(coalesce(ash.event, ' '), max(length(ash.event))over(partition by ash.sql_plan_line_id)) || ' | ' || 
    lpad(to_char(round((ratio_to_report(count(1)) over (partition by ash.sql_plan_line_id))*100, 2), 'fm999G990D00', 'nls_numeric_characters=''. '''), 5) || '% |' as top_event,
    count(1) ash_count,
    to_char(round(sum(ash.tm_delta_time)     / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ela,
    to_char(round(sum(ash.tm_delta_db_time)  / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') db_time,
    to_char(round(sum(ash.tm_delta_cpu_time) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') cpu_time,
    count(distinct ash.qc_session_id) px,
    round(max(temp_space_allocated)/1024/1024, 3) tmp,
    round(max(pga_allocated)/1024/1024, 3) pga,
    count((select df.relative_fno from dba_data_files df join dba_tablespaces dt on df.tablespace_name = dt.tablespace_name where dt.contents = 'UNDO' and df.relative_fno = ash.current_file#)) undo,
    null hist
from ash
where exists (select 0 from settings where enable_events = 1)
group by ash.sql_id,
    ash.sql_plan_hash_value,
    ash.sql_plan_line_id,
    ash.session_state, 
    ash.event
order by id nulls first, parent_id, sqlplan desc;




select event_name, wait_time_milli, sum(wait_count) wait_count from dba_hist_event_histogram where event_name = 'db file sequential read' and snap_id between 110349 and  110354
group by event_name, wait_time_milli order by 2 ;

select event_name, sum(wait_time_milli*wait_count)/sum(wait_count) from dba_hist_event_histogram where event_name = 'db file sequential read' and snap_id between 110349 and  110354 
group by event_name;

select stat_name, sum(value) From DBA_HIST_SYSSTAT where snap_id between 110349 and  110354 and 
(stat_name in ('redo size', 'transaction tables consistent reads - undo records applied', 
'data blocks consistent reads - undo records applied', 'rollback changes - undo records applied',
'undo change vector size',
'DBWR transaction table writes') 
--or stat_name like '%large tracked transactions%'
)
group by stat_name;


select event_name, sum(wait_time_milli*wait_count)/sum(wait_count) from (
SELECT       s.snap_id,
									wait_class,
									h.event_name,
									wait_time_milli,
									CASE WHEN s.begin_interval_time = s.startup_time
										THEN h.wait_count
										ELSE h.wait_count - lag (h.wait_count) over (partition BY
											event_id,wait_time_milli, h.dbid, h.instance_number, s.startup_time order by h.snap_id)
									END wait_count
								   FROM dba_hist_snapshot s,
									DBA_HIST_event_histogram h
                                    where s.dbid = h.dbid
--									AND s.dbid = &DBID
									AND s.instance_number = h.instance_number
									AND s.snap_id = h.snap_id
									AND s.snap_id BETWEEN 110349 and  110354 
									and event_name in ('db file sequential read') )group by event_name;
                                    
                                    
select * from DBA_HIST_SEG_STAT where snap_id BETWEEN 110349 and  110354 ;

select * from dba_hist_system_event where snap_id BETWEEN 110349 and  110354 and event_name = 'db file sequential read';

select * from dba_hist_sys_time_model ;
16686634 
select * From DBA_HIST_UNDOSTAT where snap_id BETWEEN 110349 and  110354 order by begin_time;

select distinct obj# from DBA_HIST_SEG_STAT where obj# in (96469,
108873,
1087195,
109549,
104142,
9188791) and  snap_id BETWEEN 110349 and  110354;


select distinct obj# from DBA_HIST_SEG_STAT st where snap_id BETWEEN 110349 and  110354 and obj# in (
select distinct current_obj# From dba_hist_active_sess_history ash where ash.snap_id BETWEEN 110349 and  110354 and ash.sql_id = '6hjs0624rwqyy' and current_obj# <> 0);


select do.object_name, st.* from dba_objects do, DBA_HIST_SEG_STAT st where do.object_id = st.obj# and snap_id BETWEEN 110349 and  110354 and obj# in (
select distinct current_obj# From dba_hist_active_sess_history ash where ash.snap_id BETWEEN 110349 and  110354 and ash.sql_id = '6hjs0624rwqyy' and current_obj# <> 0);

select distinct current_obj#, do.object_name From dba_hist_active_sess_history ash, dba_objects do where ash.snap_id BETWEEN 110349 and  110354 and ash.sql_id = '6hjs0624rwqyy'
and do.object_id(+) = ash.current_obj# and current_obj# <> 0;

select event, undo, count(1) rowcount, round(avg(time_waited)) time_waited, round(stddev(time_waited)) stddev_time_waited from (
select event, time_waited,
nvl((select 1 from dba_data_files df join dba_tablespaces dt on df.tablespace_name = dt.tablespace_name where dt.contents = 'UNDO' and df.relative_fno = ash.current_file#), 0) undo
From dba_hist_active_sess_history ash where ash.snap_id BETWEEN 110349 and  110354 and ash.sql_id = '6hjs0624rwqyy' and event is not null)
group by event, undo;

select INST_ID,
       snap_id,
       begin_interval_time,
       event_name,
       WAIT_COUNT,
       AVG_WAIT_TIME_nS,
       round(WAIT_COUNT*AVG_WAIT_TIME_nS/1000/1000) as TIME_WAITED_S
 from (
select
    instance_number as "INST_ID",
    snap_id as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    event_name,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - total_waits)
         END as WAIT_COUNT,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round((LEAD(time_waited_micro,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - time_waited_micro)
                        / (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - total_waits))
         END as AVG_WAIT_TIME_nS
from dba_hist_system_event hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     where hse.event_name in ('db file sequential read') and snap_id BETWEEN 110349 and  110354
  order by 1,2--2,1
	    ) where WAIT_COUNT is not null
        
        
        
        
select do.object_id, do.object_name, count(1) rowcount, round(avg(st.logical_reads_delta)) logical_reads, round(avg(st.buffer_busy_waits_delta)) buffer_busy_waits,
round(avg(st.db_block_changes_delta)) db_block_changes, round(avg(st.physical_reads_delta)) physical_reads, round(avg(st.physical_writes_delta)) physical_writes, 
round(avg(st.physical_reads_direct_delta)) physical_reads_direct, round(avg(st.physical_writes_direct_delta)) physical_writes_direct,round(avg(st.itl_waits_delta)) itl_waits,
round(avg(st.row_lock_waits_delta)) row_lock_waits, round(avg(st.space_used_delta)) space_used,  round(avg(st.space_allocated_delta)) space_allocated,round(avg(st.table_scans_delta)) table_scans,
round(avg(st.chain_row_excess_delta)) chain_row_excess, round(avg(st.physical_read_requests_delta)) physical_read_requests,
 round(avg(st.physical_write_requests_delta)) physical_write_requests, round(avg(st.optimized_physical_reads_delta)) optimized_physical_reads
from DBA_HIST_SEG_STAT st, dba_objects do where do.object_id = st.obj# and snap_id BETWEEN 110341 and  110341 /*and obj# in (
select distinct current_obj# From dba_hist_active_sess_history ash where ash.snap_id BETWEEN 110345 and  110348 and ash.sql_id = '6hjs0624rwqyy' and current_obj# <> 0)*/
and obj# in (96469,
109549)
group by do.object_id, do.object_name;






select event, undo, count(1) rowcount, round(avg(time_waited)) avg_time_waited, round(stddev(time_waited)) stddev_time_waited from (
select event, time_waited,
nvl((select 1 from dba_data_files df join dba_tablespaces dt on df.tablespace_name = dt.tablespace_name where dt.contents = 'UNDO' and df.relative_fno = ash.current_file#), 0) undo
From dba_hist_active_sess_history ash where ash.snap_id BETWEEN 110345 and  110348 and ash.sql_id = '6hjs0624rwqyy' and event is not null)
group by event, undo;