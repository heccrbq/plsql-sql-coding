-- Поиск всех возможных SQL_ID по куску кода
select 
    st.sql_id,
    sum(ss.executions_delta) execs, 
    round(sum(ss.elapsed_time_delta) / greatest(sum(ss.executions_delta), 1) / 1e6, 2) AS avg_elapsed_time,
    min(s.begin_interval_time) min_time, 
    max(s.begin_interval_time) max_time
--    ,(select trim(dbms_lob.substr(t.sql_text, 4000)) from dba_hist_sqltext t where t.sql_id = st.sql_id) AS text
from dba_hist_sqltext st 
    join dba_hist_sqlstat ss on st.sql_id = ss.sql_id  
    join dba_hist_snapshot s on s.snap_id = ss.snap_id and s.instance_number = ss.instance_number 
where upper(st.sql_text) like '%WITH%TMP_REMAIN%'
group by st.sql_id;

select 
    ash.sql_id, 
    ash.sql_plan_hash_value, 
    ash.sql_exec_id,
    ash.sql_exec_start,
    count(distinct ash.sql_exec_id)over() execs_ash,
    round(sum(ash.usecs_per_row) / 1e6, 2) AS avg_elapsed_time_ash,
    sum(ss.executions_delta) AS execs_sqlstat,
    round(sum(ss.elapsed_time_delta) / greatest(sum(ss.executions_delta), 1) / 1e6, 2) AS avg_elapsed_time_sqlstat,
    min(ash.snap_id) || '-' || max(ash.snap_id)
from dba_hist_active_sess_history  ash
    join dba_hist_snapshot s on s.snap_id = ash.snap_id and s.instance_number = ash.instance_number 
    join dba_hist_sqlstat ss on ss.snap_id = ash.snap_id and ss.instance_number = ash.instance_number and ss.sql_id = ash.sql_id and ss.plan_hash_value = ash.sql_plan_hash_value
where ash.sql_id = 'bfctjzphmxwqy' 
    and s.begin_interval_time >= trunc(sysdate) - 300
    and s.begin_interval_time <= trunc(sysdate) + 1
group by ash.sql_id, ash.sql_plan_hash_value, ash.sql_exec_id, ash.sql_exec_start
order by sql_exec_id;


-- snap_id выбираются из указанного sql_exec_id
select
    null id,
    null parent_id,
    null depth,
    'SQLSTAT: ' ||
    'SQL_ID = ' || st.sql_id || 
    ', hv = '   || st.plan_hash_value ||
    ', ela = '  || to_char(round(sum(st.elapsed_time_delta) / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') || 
    ', cpu = '  || to_char(round(sum(st.cpu_time_delta)     / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') || 
    ', io = '   || to_char(round(sum(st.iowait_delta)       / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', disk = ' || round(sum(st.disk_reads_delta)     / greatest(sum(st.executions_delta), 1)) ||
    ', lio = '  || round(sum(st.buffer_gets_delta)    / greatest(sum(st.executions_delta), 1)) || 
    ', r = '    || round(sum(st.rows_processed_delta) / greatest(sum(st.executions_delta), 1))  sqlplan
from dba_hist_sqlstat st
where st.sql_id = 'bfctjzphmxwqy' /*:sql_id*/
    and st.plan_hash_value = 1240908823 /*:sql_plan_hash_value*/
    and (st.instance_number, st.snap_id) in 
        (select 
            s.instance_number, s.snap_id 
        from dba_hist_snapshot s 
        where s.snap_id in 
            (select /*+no_merge */ 
                distinct ash.snap_id
            from dba_hist_active_sess_history ash
            where ash.sql_id = 'bfctjzphmxwqy' /*:sql_id*/
                and ash.sql_plan_hash_value = 1240908823 /*:sql_plan_hash_value*/
                and ash.sql_exec_id = 16777217 /*:sql_exec_id*/ ))
group by st.sql_id, st.plan_hash_value
union all
select
    null id,
    null parent_id,
    null depth,
    'ASH: ' ||
    'SQL_EXEC_ID = ' || ash.sql_exec_id ||
    ', from = ' || ash.sql_exec_start ||
    ', ela = ' || to_char(round(count(1) * 10, 2), 'fm999G990') ||
    ', tm = '  || to_char(round(sum(ash.tm_delta_time)     / 1e6, 2), 'fm999G999D00', 'nls_numeric_characters=''. ''') ||
    ', db = '  || to_char(round(sum(ash.tm_delta_db_time)  / 1e6, 2), 'fm999G999D00', 'nls_numeric_characters=''. ''') ||
    ', cpu = ' || to_char(round(sum(ash.tm_delta_cpu_time) / 1e6, 2), 'fm999G999D00', 'nls_numeric_characters=''. ''') ||
    ', waiting (%) = '  || to_char(round(count(decode(ash.session_state, 'WAITING', 1)) / count(1) * 100, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', on cpu (%) = '  || to_char(round(count(decode(ash.session_state, 'ON CPU', 1)) / count(1) * 100, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') sqlplan
from dba_hist_active_sess_history ash
where ash.sql_id = 'bfctjzphmxwqy' /*:sql_id*/
    and ash.sql_plan_hash_value = 1240908823 /*:sql_plan_hash_value*/
    and ash.sql_exec_id = 16777217 /*:sql_exec_id*/
group by ash.sql_exec_id, ash.sql_exec_start;
--union all

with ash as
(
    select /*+materialized*/
        *
    from dba_hist_active_sess_history ash
    where ash.sql_id = 'bfctjzphmxwqy' /*:sql_id*/
        and ash.sql_plan_hash_value = 1240908823 /*:sql_plan_hash_value*/
        and ash.sql_exec_id = 16777217 /*:sql_exec_id*/ 
)
select
    sp.id, sp.parent_id, nullif(sp.depth - 1, -1) depth, 
    lpad(' ', 4*depth) || sp.operation || nvl2(sp.optimizer, '  Optimizer=' || sp.optimizer, null) ||
    nvl2(sp.options, ' (' || sp.options || ')', null) || 
    nvl2(sp.object_name, ' OF ''' || nvl2(sp.object_owner, sp.object_owner || '.', null) || sp.object_name || '''', null) ||
    decode(sp.object_type, 'INDEX (UNIQUE)', ' (UNIQUE)') ||
    '  (Cost=' || cost || ' Card=' || sp.cardinality || ' Bytes=' || bytes || ')' sqlplan,
    ash.ash_count,
    ash.db_time,
    ash.cpu_time,
    ash.px
from dba_hist_sql_plan sp
    outer apply
        (select
            count(1) ash_count,
            sum(ash.tm_delta_db_time) db_time,
            sum(ash.tm_delta_cpu_time) cpu_time,
            count(distinct qc_session_id) px
        from ash
        where ash.sql_id = sp.sql_id
            and ash.sql_plan_hash_value = sp.plan_hash_value
            and ash.sql_exec_id = 16777217 /*:sql_exec_id*/ 
            and ash.sql_plan_line_id = sp.id) ash
where sp.sql_id = 'bfctjzphmxwqy' /*:sql_id*/
    and sp.plan_hash_value = 1240908823 /*:sql_plan_hash_value*/
order by sp.id
