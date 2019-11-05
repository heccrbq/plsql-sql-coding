select sid, sql_id, sql_child_number, event from v$session where sid <> userenv('sid') and status = 'ACTIVE' and osuser = 'dvbykov';


SQL > SELECT /*abrakadabra*/ /*+gather_plan_statistics*/ ...
			  
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
select sql_id, plan_hash_value, child_number, sql_text from v$sql where sql_fulltext like '%abrakadabra%';
select * from table(dbms_xplan.display_cursor(sql_id => 'd2mdtjp9dynrw'/*:sql_id*/, cursor_child_no => 3/*:sql_child_number*/, format => 'ALLSTATS LAST'));
select id, name, isdefault, value from v$sql_optimizer_env where sql_id = '3srshtyjrcghw'/*:sql_id*/ order by name;

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
    ash.sql_opname,
    ash.sql_plan_line_id,
    ash.sql_plan_operation,
    ash.sql_plan_options,
--    ao.object_name,
--    ash.current_obj#,
    ash.event,
    count(1) wait_count,
    sum(delta_read_io_requests) io_req,
    round(sum(tm_delta_cpu_time)/1e6, 4) cpu_time_sec,
    round(sum(tm_delta_db_time)/1e6, 4) db_time_sec,
    round(sum(count(1))over(partition by sql_plan_line_id) / sum(count(1))over() * 100, 2) percent_per_line, 
    round(sum(count(1))over(partition by sql_plan_line_id, session_state) / sum(count(1))over(partition by sql_plan_line_id) * 100, 2) percent_per_line_state, 
    round(sum(count(1))over(partition by sql_plan_line_id, session_state, event) / sum(count(1))over(partition by sql_plan_line_id, session_state) * 100, 2) percent_per_line_state_event
from v$active_session_history ash
--    , all_objects ao
where ash.sql_id = '356xmrh0vbtnj'/*:sql_id*/
--	and ash.sql_plan_hash_value = 3682407720/*:sql_plan_hash_value*/
--	and ash.sql_child_number = 0 /*:sql_child_number*/
--    and ao.object_id(+) = ash.current_obj#
group by ash.session_state,
    ash.sql_opname,
    ash.sql_plan_line_id,
    ash.sql_plan_operation,
    ash.sql_plan_options,
--    ao.object_name,
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
    s.sql_id, s.plan_hash_value, s.child_number, s.loaded_versions,
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
where s.sql_id = '3srshtyjrcghw'/*:sql_id*/
	and s.plan_hash_value = 3682407720/*:sql_plan_hash_value*/
--	and s.child_number = 3/*:sql_child_number*/
    and s.sql_id = ss.sql_id(+)
    and s.plan_hash_value = ss.plan_hash_value(+);


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
    decode(column_value, 0, null, id) id,
    decode(column_value, 0, 'SQL_ID  ' || sql_id || ', child number  ' || child_number || ', plan hash value  ' || plan_hash_value, 
	lpad(' ', depth) || operation) operation, options,
    object_owner, object_name, object_type,
    decode(column_value, 0, null, optimizer) optimizer,
    access_predicates, filter_predicates, --xmlroot(xmltype.createxml(other_xml), version '1.0" encoding="windows-1251') other_xml
    --
    cardinality, bytes, 
    decode(column_value, 0, null, cost) cost, cpu_cost, io_cost,
    round(last_elapsed_time / 1e6, 4) elapsed_time_sec, time, active_time, temp_space,
    last_output_rows, last_cr_buffer_gets/*consistent mode*/, last_disk_reads, last_cr_buffer_gets - last_disk_reads diff_read,
    last_cu_buffer_gets/*current mode*/, last_disk_writes,
    decode(column_value, 0, null, executions) executions, 
    last_execution, last_memory_used, last_degree, optimal_executions, onepass_executions, multipasses_executions
from v$sql_plan_statistics_all s,
    table(sys.odcinumberlist(0,1)) t
where t.column_value(+) >= s.id
    and sql_id = 'd2mdtjp9dynrw'/*:sql_id*/
--	and plan_hash_value = 3682407720/*:sql_plan_hash_value*/
--	and child_number = 3/*:sql_child_number*/
order by plan_hash_value, child_number, s.id;


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
                    'redo size',
                    'bytes sent via SQL*Net to client',
                    'bytes received via SQL*Net from client',
                    'sorts (memory)', 'sorts (rows)',
                    'rows fetched via callback',
                    'undo change vector size',
                    'parse count (failures)', 'parse count (hard)', 'parse count (total)', 'parse time cpu', 'parse time elapsed');


select ss.sid, ss.statistic#, st.name, ss.value from v$sesstat ss, v$statname st where ss.statistic# = st.statistic# and sid = userenv('sid') and value > 0 order by st.name;


--select * from v$sqltext_with_newlines where sql_id = '9tjz886v2bdqw';
