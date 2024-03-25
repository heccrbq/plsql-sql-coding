
-- текущие показатели утилизации ресурсов
select * From v$sysmetric where group_id = 2 and metric_name in ('Database CPU Time Ratio', 'Host CPU Utilization (%)', 'CPU Usage Per Sec',
                                                                 'Physical Reads Per Sec', 'Logical Reads Per Sec');


-- текущие метрики системы по утилизации ресурсов: цпу и чтение
select * from v$sysmetric_summary where group_id = 2 and metric_name in ('Database CPU Time Ratio', 'Host CPU Utilization (%)', 'CPU Usage Per Sec',
                                                                         'Physical Reads Per Sec', 'Logical Reads Per Sec');


-- метрики на истории
select * from v$sysmetric_history where group_id = 2 and metric_name in ('Database CPU Time Ratio', 'Host CPU Utilization (%)', 'CPU Usage Per Sec',
                                                                         'Physical Reads Per Sec', 'Logical Reads Per Sec')
order by metric_name, begin_time desc;


-- эвенты пользователя и их средним значением времени ожидания
select event, avg(average_wait) y, sum(time_waited) x From v$session_event where sid in (select sid from v$session  where osuser = 'u00033859') group by event order by x desc;


-- основные параметры темп тбс (сколько выделено, размечено, занято, свободно и тд)
select 
	-- temp tbs info --
    ss.tablespace_name
    ,t.contents
    ,t.segment_space_management
	-- temp memory usage --
    ,round(tf.total_space/1024/1024/1024, 3)  as "Total Temp space, Gb"
    ,round(tf.useful_space/1024/1024/1024, 3) as "Useful Temp space, Gb"
    ,round(ss.total_blocks * t.block_size/1024/1024/1024, 3) as "Formatted Temp space, Gb"
    ,round(ss.used_blocks * t.block_size/1024/1024/1024,  3) as "Used Temp space, Gb"
    ,round(tfs.free_space/1024/1024/1024,  3)       as "Free Temp space, Gb"
    ,round(100 * tfs.free_space/tf.useful_space, 2) as "pct free, %"
from v$sort_segment ss
    join dba_tablespaces t on t.tablespace_name = ss.tablespace_name
    join dba_temp_free_space tfs on tfs.tablespace_name = ss.tablespace_name
    outer apply
        (select 
             sum(tf.bytes) total_space
             ,sum(tf.user_bytes) useful_space
        from dba_temp_files tf 
        where tf.tablespace_name = ss.tablespace_name) tf;
        

-- посессионное использование темпа
select
    -- session info --
    s.username
    ,s.osuser
    -- temp tbs info --
    ,su.tablespace
    ,su.contents
    ,su.segtype
	-- temp memory usage --
    ,round(sum(su.blocks * t.block_size)/1024/1024/1024, 3) as "Used Temp space, Gb"
    ,round((ratio_to_report(sum(su.blocks))over())*100, 2) as "pct used, %"
from v$sort_usage su
    left join dba_tablespaces t on tablespace_name = su.tablespace
    left join v$session s on s.saddr = su.session_addr
group by s.username
    ,s.osuser
    ,su.tablespace
    ,su.contents
    ,su.segtype
order by 6 desc;


-- используемый темп в разрезе sql_id на данных ASH за определенный период
select cast(sample_time as date) dt, sql_id, max(temp_space_allocated)/1024/1024/1024 x from dba_hist_active_sess_history where sample_time >= timestamp'2021-02-11 16:00:00' 
group by cast(sample_time as date), sql_id 
--order by x desc nulls last, dt desc nulls last
) group by dt order by 1 desc;


-- используемый темп конкретного os_user в разбивку по SID'у и sql_id
with t as (select /*+materialize */ distinct sql_id, session_id sid from v$active_session_history where session_id in (
select sid from v$session where osuser = 'DVBykov'))
select round(sum(TEMP_SPACE_ALLOCATED)/1024/1024/1024, 2) x, t.sid, t.sql_id  from DBA_HIST_ACTIVE_SESS_HISTORY h join t on t.sql_id = h.sql_id where h.sample_time >= date'2021-02-11'
group by t.sid, t.sql_id
order by x desc nulls last;


-- статистики сессии: использование pga/uga, temp, multipass при HJ, sorts
select 
	sess.username  as username
    ,sess.sid      as session_id
    ,sess.serial#  as session_serial
    ,sess.program  as session_program
    ,sess.server   as session_mode
    ,name.name
    ,case when name like '%session%' then round(stat.value/1024/1024, 2) else stat.value end as "current memory (in MB)"
    ,sess.sql_id,
    sum(case when name like '%session%' or name like '%temp%' then round(stat.value/1024/1024, 2) end)over(partition by sess.sql_id, name.name) x
 from v$session    sess
    ,v$sesstat    stat
    ,v$statname   name
where sess.sid = stat.sid
    and stat.statistic# = name.statistic#
    and name.name   in ('session pga memory','session pga memory max','session uga memory','session uga memory max', 
                        'sorts (memory)', 'sorts (disk)', 'sorts (rows)',
                        'temp space allocated (bytes)', 'physical reads direct temporary tablespace', 'physical writes direct temporary tablespace',
                        'workarea memory allocated' , 'workarea executions - optimal', 'workarea executions - onepass' , 'workarea executions - multipass')
    and sess.osuser = 'u00033859'
-- and sess.sql_id in ('8sxn62mp3umvn','adczhx0hpytd2');
-- and name.name like '%workarea executions%';
;

-- тайм модель по нагрузке на сервер
-- DBA_HIST_SYS_TIME_MODEL
select * from v$sys_time_model where stat_name in ( 'DB CPU', 
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
                                                    
                                   dba_users                 
-- оцениваем исполняемые запросы с разрезе конкретного пользователя на основе ASH
select ash.session_id sid, ash.session_serial# serial#, min(ash.sample_time) sample_time, ash.sql_id, ash.sql_exec_id, ash.sql_opname, 
    --
    count(1) wait_count, 
    sum(ash.tm_delta_db_time) db_time,
    sum(ash.tm_delta_cpu_time) cpu_time,
    sum(ash.delta_read_io_bytes) rbyt,
    sum(ash.delta_write_io_bytes) wbyt,
    max(ash.pga_allocated) pga,
    max(ash.temp_space_allocated) temp,
    substr(s.sql_text, 1, 100) subprogram,
--    case
--        when ash.sql_opcode = 47 then (select object_name || '.' || procedure_name from dba_procedures p where p.object_id = ash.plsql_object_id and p.subprogram_id = ash.plsql_subprogram_id)
--        when ash.sql_opcode in (3/*SELECT*/, 85/*TRUNCATE*/) then substr(s.sql_text, 1, 100)
--        else '??? (' || to_char(ash.sql_opcode) || ')'
--    end subprogram,
    (select o.object_name from dba_objects o where o.object_id = s.program_id) object_name,
    s.program_line#
from v$active_session_history ash
    left join v$sqlarea s on s.sql_id = ash.sql_id
where ash.user_id = 381
group by ash.session_id, ash.session_serial#, ash.sql_id, ash.sql_exec_id, ash.sql_opcode, ash.sql_opname, ash.plsql_object_id, ash.plsql_subprogram_id, 
    s.program_id, s.program_line#, substr(s.sql_text, 1, 100)
order by ash.session_id, ash.session_serial#, sample_time;

                                                    
/**
 * =============================================================================================
 * Запрос генерации AWR отчета в формате HTML на текущей БД с указанием snapshot'ов
 * =============================================================================================
 * @param   btime (DATE)   Стартовое время генерации отчета
 * @param   etime (DATE)   Конечное время генерации отчета
 * =============================================================================================
 * Описание полей:
 *  - file#  : имя сгенерированного отчета
 *  - output : содержание отчета
 */
with source as (
    select timestamp'2023-09-03 04:47:00' btime, timestamp'2023-09-03 05:37:00' etime from dual
),
awr as (
    select 
        d.name, d.dbid, d.inst_id, lt.start_snap_id, lt.end_snap_id, lt.bit, lt.eit
    from gv$database d,
    lateral(
        select min(snap_id) start_snap_id, max(snap_id) end_snap_id, min(sn.begin_interval_time) bit, max(sn.end_interval_time) eit
        from dba_hist_snapshot sn, source s
        where sn.dbid = d.dbid and sn.instance_number = d.inst_id 
            and (s.btime between sn.begin_interval_time and sn.end_interval_time 
                or s.etime between sn.begin_interval_time and sn.end_interval_time)) lt
)
--select * From awr;
select
    'AWR_' || lower(awr.name) || '_' || awr.inst_id || '_' || to_char(awr.bit, 'hh24mi') || '_' || to_char(awr.eit, 'hh24mi') || '.html' file#,
    dbms_xmlgen.convert(xmlagg(xmlelement(output, t.output || chr(10)) order by rownum).extract('//text()').getclobval(),1) output
from awr,
    table(dbms_workload_repository.awr_report_html(l_dbid     => awr.dbid, 
                                                   l_inst_num => awr.inst_id, 
                                                   l_bid      => awr.start_snap_id, 
                                                   l_eid      => awr.end_snap_id)) t
group by awr.name, awr.dbid, awr.inst_id, awr.start_snap_id, awr.end_snap_id, awr.bit, awr.eit;