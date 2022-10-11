select sid,  serial#, sql_id, sql_child_number, event, ownerid, taddr,
	'alter system kill session ''' || sid || ',' || serial# || ''' immediate;' x 
from v$session where sid <> userenv('sid') and status = 'ACTIVE' and osuser = 'DVBykov';


set timing on
set serveroutput on size unl
declare
    vtype       NUMBER := 0;
    vcopydate   DATE := date'2021-03-10';
    cbranch     INTEGER := 1;
    --
    cursor cur is
	select /*abrakadabra*/ /*+gather_plan_statistics*/
	...
	--
	type tcur is table of cur%rowtype;
    v_cur tcur;
begin
    open cur;
    fetch cur bulk collect into v_cur;
    close cur;
    
    dbms_output.put_line(v_cur.count);
end;
/

/**
 * =============================================================================================
 * Набор из трех скриптов:
 *	- получения sql_id, plan_hash_value, child_number и текст запроса
 *	- dbms_xplan план запроса с предикатами
 *	- параметры оптимизатора, с которыми был выполнен запрос
 * =============================================================================================
 * @param   sql_id   			Уникальный идентификатор запроса
 * @param   sql_child_number	?
 * =============================================================================================
 */

select last_load_time, sql_id, plan_hash_value, child_number, sql_text from v$sql where sql_fulltext like '%abrakadabra%' and sql_fulltext not like '%v$sql%' order by to_date(last_load_time, 'yyyy-mm-dd/hh24:mi:ss') desc;
select * from table(dbms_xplan.display_cursor(sql_id => 'g8uufyzmn071x'/*:sql_id*/, cursor_child_no => 0/*:sql_child_number*/, format => 'ALLSTATS LAST +projection'));
select id, name, isdefault, value from v$sql_optimizer_env where sql_id = '3srshtyjrcghw'/*:sql_id*/ order by name;

SELECT DBMS_SQLTUNE.report_sql_monitor(
  sql_id       => 'fg007sgmc335p',
  type         => 'TEXT',
  report_level => 'ALL') AS report
FROM dual;

select 
    session_state, event, wait_class, count(1) wait_count, 
    round(sum(time_waited)/1e3, 2) time_waited,
    round((ratio_to_report(count(1)) over ())*100, 2) as percent
from v$active_session_history
where sql_id = 'd2mdtjp9dynrw'/*:sql_id*/
	and sql_plan_hash_value = 3682407720/*:sql_plan_hash_value*/
	and sql_child_number = 3 /*:sql_child_number*/
group by session_state, event, wait_class
order by wait_count desc;


/**
 * =============================================================================================
 * Среднее время работы указанного запроса в каждом из снепшотов.
 * =============================================================================================
 * @param   sql_id   				Уникальный идентификатор запроса
 * @param   sql_plan_hash_value		Хэш значение плана выполнения искомого запроса
 * =============================================================================================
 * Описание полей:
 *	- session_state : 
 *  - sql_opname : 
 *  - sql_plan_line_id : 
 *  - sql_plan_operation : 
 *  - sql_plan_options :  
 *	- object_name : 
 *	- current_obj : 
 *	- event : 
 *  - wait_count : 
 *  - io_req : 
 *  - cpu_time_sec : 
 *  - db_time_sec : 
 *  - percent_per_line : 
 *	- percent_per_line_state : 
 *	- percent_per_line_state_event : 
 * =============================================================================================
 */
select
    ash.session_state, 
--    ash.sql_opname,
    ash.sql_plan_line_id,
    ash.sql_plan_operation,
    ash.sql_plan_options,
    ao.object_name,
--    ash.current_obj#,
    ash.event,
    count(1) wait_count,
    sum(delta_read_io_requests) io_req,
--    round(sum(wait_time)/1e6, 4) wait_time_sec,
    round(sum(tm_delta_cpu_time)/1e6, 4) cpu_time_sec,
--    round(sum(time_waited)/1e6, 4) time_waited_sec,
    round(sum(tm_delta_db_time)/1e6, 4) db_time_sec,    
--    round(sum(tm_delta_time)/1e6, 4) tm_delta_sec,
    round(sum(sum(delta_time))over(partition by sql_plan_line_id)/1e6, 4) delta_time_per_line_sec,
    round(sum(count(1))over(partition by sql_plan_line_id) / sum(count(1))over() * 100, 2) percent_per_line, 
    round(sum(count(1))over(partition by sql_plan_line_id, session_state) / sum(count(1))over(partition by sql_plan_line_id) * 100, 2) percent_per_line_state, 
    round(sum(count(1))over(partition by sql_plan_line_id, session_state, event) / sum(count(1))over(partition by sql_plan_line_id, session_state) * 100, 2) percent_per_line_state_event
from v$active_session_history ash
    , all_objects ao
where ash.sql_id = '356xmrh0vbtnj'/*:sql_id*/
--	and ash.sql_plan_hash_value = 3682407720/*:sql_plan_hash_value*/
--	and ash.sql_child_number = 0 /*:sql_child_number*/
    and ao.object_id(+) = ash.current_obj#
group by ash.session_state,
    ash.sql_opname,
    ash.sql_plan_line_id,
    ash.sql_plan_operation,
    ash.sql_plan_options,
    ao.object_name,
--    ash.current_obj#,
    ash.event
order by ash.sql_plan_line_id, min(sample_id);


/**
 * =============================================================================================
 * Среднее время работы указанного запроса в каждом из снепшотов.
 * =============================================================================================
 * @param   sql_id   				Уникальный идентификатор запроса
 * @param   sql_plan_hash_value		Хэш значение плана выполнения искомого запроса
 * =============================================================================================
 * Описание полей:
 *	- session_state : 
 *  - sql_opname : 
 *  - sql_plan_line_id : 
 *  - sql_plan_operation : 
 *  - sql_plan_options :  
 *	- object_name : 
 *	- current_obj : 
 *	- event : 
 *  - wait_count : 
 *  - io_req : 
 *  - cpu_time_sec : 
 *  - db_time_sec : 
 *  - percent_per_line : 
 *	- percent_per_line_state : 
 *	- percent_per_line_state_event : 
 * =============================================================================================
 */
select ash.session_id, ash.session_serial#,
    ash.sql_id, ash.sql_child_number, ash.sql_opname, 
    ash.sql_adaptive_plan_resolved, ash.sql_plan_hash_value, ash.sql_plan_line_id, ash.sql_plan_operation, ash.sql_plan_options,
    ash.qc_session_id, ash.px_flags,
    ash.event, ash.p1text, ash.p1, decode(ash.event, 'Disk file operations I/O', decode(ash.p1, 1, 'file creation',
                                                                                                2, 'file open',
                                                                                                3, 'file resize',
                                                                                                4, 'file deletion',
                                                                                                5, 'file close',
                                                                                                6, 'wait for all aio requests to finish',
                                                                                                7, 'write verification',
                                                                                                8, 'wait for miscellaneous io (ftp, block dump, passwd file)',
                                                                                                9, 'read from snapshot files'),
                                                     'db file parallel read',    (select name from v$datafile df where df.file# = ash.p1)) p1value,
               ash.p2text, ash.p2, decode(ash.event, 'Disk file operations I/O', (select name from v$datafile df where df.file# = ash.p3)) p2value,
               ash.p3text, ash.p3, decode(ash.event, 'Disk file operations I/O', decode(ash.p3, 0, 'Other',
                                                                                                1, 'Control File',
                                                                                                2, 'Data File',
                                                                                                3, 'Log File',
                                                                                                4, 'Archive Log',
                                                                                                6, 'Temp File',
                                                                                                9, 'Data File Backup',
                                                                                               10, 'Data File Incremental Backup',
                                                                                               11, 'Archive Log Backup',
                                                                                               12, 'Data File Copy',
                                                                                               17, 'Flashback Log',
                                                                                               18, 'Data Pump Dump File',
                                                                                                   'unknown ' || ash.p3)) p3value,
--                                                                                             'select distinct filetypename from dba_hist_iostat_filetype where filetype_id = ' || ash.p3
    ash.wait_class, ash.session_state, ash.time_waited, ash.blocking_session_status, ash.blocking_session,
    ash.current_obj#, ash.current_file#, ash.current_block#, ash.current_row#,
    ash.pga_allocated, ash.temp_space_allocated
from v$active_session_history ash
where ash.sql_id = 'd2mdtjp9dynrw'/*:sql_id*/
	and ash.sql_plan_hash_value = 3682407720/*:sql_plan_hash_value*/
	and ash.sql_child_number = 3 /*:sql_child_number*/
order by ash.sql_plan_line_id, sample_id;


/**
 * =============================================================================================
 * Среднее время работы указанного запроса в каждом из снепшотов.
 * =============================================================================================
 * @param   sql_id   				Уникальный идентификатор запроса
 * @param   sql_plan_hash_value		Хэш значение плана выполнения искомого запроса
 * =============================================================================================
 * Описание полей:
 *	- session_state : 
 *  - sql_opname : 
 *  - sql_plan_line_id : 
 *  - sql_plan_operation : 
 *  - sql_plan_options :  
 *	- object_name : 
 *	- current_obj : 
 *	- event : 
 *  - wait_count : 
 *  - io_req : 
 *  - cpu_time_sec : 
 *  - db_time_sec : 
 *  - percent_per_line : 
 *	- percent_per_line_state : 
 *	- percent_per_line_state_event : 
 * =============================================================================================
 */
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
where s.sql_id = '7dft8r0rshm1z'/*:sql_id*/
--	and s.plan_hash_value = 3682407720/*:sql_plan_hash_value*/
--	and s.child_number = 3/*:sql_child_number*/
    and s.sql_id = ss.sql_id(+)
    and s.plan_hash_value = ss.plan_hash_value(+);


/**
 * =============================================================================================
 * 
 * =============================================================================================
 * @param   sql_id   				Уникальный идентификатор запроса
 * @param   sql_plan_hash_value		Хэш значение плана выполнения искомого запроса
 * =============================================================================================
 * Описание полей:
 *	- id : 
 *	- depth : 
 *	- operation : 
 * =============================================================================================
 * alter session set statistics_level = all
 * =============================================================================================
 */
select
    decode(column_value, 0, null, id) id,
    max(depth)over(partition by sql_id, plan_hash_value, child_number) - decode(column_value, 0, null, depth) depth,
    decode(column_value, 0, 
		'SQL_ID  ' || sql_id || ', child number  ' || child_number || ', plan hash value  ' || plan_hash_value,
        lpad(' ', 2*depth) || operation || nvl2(optimizer, ' (' || optimizer || ')', null)) operation, 
    options, object_owner, object_name, object_type,
    access_predicates, filter_predicates, --xmlroot(xmltype.createxml(other_xml), version '1.0" encoding="windows-1251') other_xml,
    --
    cardinality, bytes, 
    decode(column_value, 0, null, cost) cost, cpu_cost, io_cost,
    round(last_elapsed_time / 1e6, 4) elapsed_time_sec, time, active_time,
    last_output_rows, last_cr_buffer_gets/*consistent mode*/, last_disk_reads, last_cr_buffer_gets - last_disk_reads diff_read,
    last_cu_buffer_gets/*current mode*/, last_disk_writes,
    starts, executions,	last_execution, 
    last_degree, optimal_executions, onepass_executions, multipasses_executions,
    temp_space, last_memory_used, last_tempseg_size, estimated_optimal_size, estimated_onepass_size
from v$sql_plan_statistics_all s,
    table(sys.odcinumberlist(0,1)) t
where t.column_value(+) >= s.id
    and sql_id = 'gaby4cyyqbsx1'/*:sql_id*/
--	and plan_hash_value = 3682407720/*:sql_plan_hash_value*/
--	and child_number = 3/*:sql_child_number*/
order by plan_hash_value, child_number, s.id, t.column_value;



-- SQL PLAN in TOAD
select 
    decode(t.column_value, 0, null, sp.id) id, sp.parent_id, nullif(sp.depth - 1, -1) depth, 
    decode(t.column_value, 0, 
        -- sql_id, cn = sql child number, hv = plan hash value, ela = elapsed time per seconds, disk = physical read, lio = consistent gets (cr + cu), r = rows processed
		'SQL_ID = ' || s.sql_id || ', hv = ' || s.plan_hash_value || ', cn = ' || s.child_number || 
        ', ela = ' || replace(round(s.elapsed_time / 1e6, 2), ',', '.') || 
		', cpu = ' || replace(round(s.cpu_time / 1e6, 2), ',', '.') ||
		', io = ' || replace(round(s.user_io_wait_time / 1e6, 2), ',', '.') ||
        ', disk = ' || s.disk_reads || ', lio = ' || s.buffer_gets || ', r = ' || s.rows_processed,
        --
        lpad(' ', 4*depth) || sp.operation || nvl2(sp.optimizer, '  Optimizer=' || sp.optimizer, null) ||
        nvl2(sp.options, ' (' || sp.options || ')', null) || 
        nvl2(sp.object_name, ' OF ''' || nvl2(sp.object_owner, sp.object_owner || '.', null) || sp.object_name || '''', null) ||
        decode(sp.object_type, 'INDEX (UNIQUE)', ' (UNIQUE)') ||
        '  (Cost=' || cost || ' Card=' || sp.cardinality || ' Bytes=' || bytes || ')') sqlplan,
    (select count(1) from v$active_session_history ash 
    where ash.sql_id(+) = sp.sql_id and ash.sql_plan_hash_value(+) = sp.plan_hash_value  and ash.sql_child_number(+) = sp.child_number and ash.sql_plan_line_id(+) = sp.id) ash_wait_count,
    sps.last_starts,
    sps.last_output_rows,
    sps.elapsed_time
    ,sp.access_predicates
    ,sp.filter_predicates
	,sp.projection
from v$sql s
    join v$sql_plan sp on sp.address = s.address and sp.child_address = s.child_address
    left join v$sql_plan_statistics sps on sps.address = sp.address and sps.child_address = sp.child_address and sp.id = sps.operation_id
    left join table(sys.odcinumberlist(0,1)) t on t.column_value >= sp.id
where s.sql_id = '7ws7mwbu656r1'
order by s.plan_hash_value, s.child_number, sp.id, t.column_value;





-- undo + hist

with source as 
(
    select '6vc7dpyv10fnd' sql_id, 1661035582 plan_hash_value, 0 child_number, 16777216 sql_exec_id from dual
),
settings as 
(
    select 0 enable_events from dual
),
ash as
(   -- строки с sql_exec_id is null and in_parse = 'Y' and in_hard_parse = 'Y' учтены в ASH: parse - в это время происходит парсинг запроса.
    select /*+materialize*/
        ash.*
    from v$active_session_history ash
		join source s on ash.sql_id = s.sql_id 
					 and ash.sql_plan_hash_value = s.plan_hash_value 
					 and ash.sql_exec_id = s.sql_exec_id
                     and ash.sql_child_number = s.child_number
)

-- Статистика выполнения запроса по sql_id и plan_hash_value из gv$sql
select
    null id,
    null parent_id,
    null depth,
    'SQLSTAT: ' ||
    'SQL_ID = ' || st.sql_id || 
    ', hv = '   || st.plan_hash_value ||
    ', cn = '   || st.child_number ||
    ', e = '    || sum(st.executions) || 
    ', ela = '  || to_char(round(sum(st.elapsed_time) / greatest(sum(st.executions), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') || 
    ', cpu = '  || to_char(round(sum(st.cpu_time)     / greatest(sum(st.executions), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') || 
    ', io = '   || to_char(round(sum(st.user_io_wait_time)       / greatest(sum(st.executions), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', disk = ' || round(sum(st.disk_reads)           / greatest(sum(st.executions), 1)) ||
    ', lio = '  || round(sum(st.buffer_gets)          / greatest(sum(st.executions), 1)) || 
    ', r = '    || round(sum(st.rows_processed)       / greatest(sum(st.executions), 1)) ||
    ', px = '   || round(sum(st.px_servers_executions)     / greatest(sum(st.executions), 1)) sqlplan,
    null ash_count,
    to_char(round(sum(st.elapsed_time) / greatest(sum(st.executions), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ela,
    null db_time,
    to_char(round(sum(st.cpu_time)     / greatest(sum(st.executions), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') cpu_time,
    null px,
    null tmp,
    null pga,
    null undo,
    null hist
from gv$sql st
where (st.sql_id, st.plan_hash_value, child_number) in (select sql_id, plan_hash_value, child_number from source)
--    and (st.instance_number, st.snap_id) in 
--        (select 
--            s.instance_number, s.snap_id 
--        from dba_hist_snapshot s 
--        where s.snap_id in 
--            (select /*+no_merge */ distinct ash.snap_id from ash))
group by st.sql_id, st.plan_hash_value, st.child_number
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
                from v$active_session_history h 
                where h.sql_id = ash.sql_id and h.sql_plan_hash_value = ash.sql_plan_hash_value and h.sql_child_number = ash.sql_child_number 
                    and h.sql_exec_id = ash.sql_exec_id and h.session_id = ash.session_id and h.session_serial# = ash.session_serial#
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
group by ash.sql_id, ash.sql_plan_hash_value, ash.sql_child_number, ash.sql_exec_id, ash.sql_exec_start, ash.session_id, ash.session_serial#
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
from gv$sql_plan sp
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
where (sp.sql_id, sp.plan_hash_value, child_number) in (select sql_id, plan_hash_value, child_number from source)
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




select sid,
    event, 
    total_waits, total_timeouts,
    time_waited, average_wait, max_wait, time_waited_micro,
    wait_class
from v$session_event 
where sid = userenv('sid');


select ss.sid, ss.statistic#, st.name, ss.value 
from v$sesstat ss, v$statname st
where ss.statistic# = st.statistic# 
    and sid = userenv('sid') 
    and st.name in ('recursive calls', 
                    'db block gets', --'db block gets direct', 'db block gets from cache', 'db block gets from cache (fastpath)', 'db block changes',                    
                    'consistent gets', --'consistent gets direct', 'consistent gets examination', 'consistent gets examination (fastpath)', 'consistent gets from cache', 'consistent gets pin', 'consistent gets pin (fastpath)',
                    'physical reads', --'physical reads cache', 'physical reads cache prefetch', 'physical reads direct', 'physical reads direct (lob)', 'physical reads direct temporary tablespace',
                    'redo size', --'redo writes', 'redo blocks written', 'redo synch writes',
                    'bytes sent via SQL*Net to client',
                    'bytes received via SQL*Net from client',
                    'sorts (memory)', 'sorts (rows)',
                    'rows fetched via callback',
                    'undo change vector size', -- 'total number of undo segments dropped', 'gc undo block disk read', 'data blocks consistent reads - undo records applied', 'rollback changes - undo records applied',
					'table fetch continued row', -- chained & migrated rows
                    'parse count (failures)', 'parse count (hard)', 'parse count (total)', 'parse time cpu', 'parse time elapsed');


select ss.sid, ss.statistic#, st.name, ss.value from v$sesstat ss, v$statname st where ss.statistic# = st.statistic# and sid = userenv('sid') and value > 0 order by st.name;


select * from v$session_wait where sid = 278;

Значение полей v$session_wait:


WAIT_TIME  
 NUMBER 
 A nonzero value is the session's last wait time. A zero value means the session is currently waiting. 
 
SECONDS_IN_WAIT 
 NUMBER 
 The seconds in wait 
 
STATE 
 VARCHAR2 
 Wait state: 

0 - WAITING (the session is currently waiting) 

-2 - WAITED UNKNOWN TIME (duration of last wait is unknown) 

-1 - WAITED SHORT TIME (last wait <1/100th of a second) 

>0 - WAITED KNOWN TIME (WAIT_TIME = duration of last wait) 
