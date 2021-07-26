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

-- эвенты пользователя и их средним значением времени ожидания
select event, avg(average_wait) y, sum(time_waited) x From v$session_event where sid in (select sid from v$session  where osuser = 'DVBykov') group by event order by x desc;

-- текущие метрики системы по утилизации ресурсов: цпу и чтение
select * from v$sysmetric_summary where group_id = 2 and metric_name in ('Database CPU Time Ratio', 'Host CPU Utilization (%)', 'CPU Usage Per Sec',
                                                                         'Physical Reads Per Sec', 'Logical Reads Per Sec');

-- метрики на истории
select * from v$sysmetric_history where group_id = 2 and metric_name in ('CPU Usage Per Sec') order by metric_name, begin_time desc;

-- текущие показатели утилизации ресурсов
select * From v$sysmetric where group_id = 2 and metric_name in ('Database CPU Time Ratio', 'Host CPU Utilization (%)', 'CPU Usage Per Sec',
                                                                 'Physical Reads Per Sec', 'Logical Reads Per Sec');

-- параметры тбс с используемым пространством
select * From dba_hist_tbspc_space_usage;

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
    and sess.osuser = 'DVBykov'
-- and sess.sql_id in ('8sxn62mp3umvn','adczhx0hpytd2');
-- and name.name like '%workarea executions%';

-- Использование ЦПУ посессионно, количество прочитанных и измененных блоков с фильтром по sql_id
select
   s.username,
   t.sid,
   s.sql_id,
   s.event,
   s.serial#,
   sum(value/100) as "cpu usage (seconds)",
   round((ratio_to_report(sum(value)) over ())*100, 2) as "pct, %",
   round((ratio_to_report(sum(value)) over ())*100, 2) as "pct by sqlid, %",
   io.block_gets,
   io.consistent_gets,
   io.physical_reads,
   io.block_changes,
   io.consistent_changes
from    v$session s
   inner join v$sesstat t on t.sid = s.sid
   inner join v$statname n on n.statistic# = t.statistic#
   inner join v$sess_io io on io.sid = s.sid
where s.status = 'ACTIVE'
   and n.name like '%CPU used by this session%'
   and s.username is not null
   and s.sql_id in ('8sxn62mp3umvn','adczhx0hpytd2')
group by username,t.sid,s.serial#, io.block_gets,
   io.consistent_gets,
   io.physical_reads,
   io.block_changes,
   io.consistent_changes,
   s.sql_id, s.event
order by 6 desc;
