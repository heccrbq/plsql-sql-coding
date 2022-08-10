-- процы и ядра
select * from v$osstat where stat_name in ( -- физические процессоры
                                            'NUM_CPU_SOCKETS',
                                            -- общее количество ядер на всех процах
                                            'NUM_CPU_CORES',
                                            -- количество логических ядер( Hyper-threading on/off - технология виртуализации, которая одно ядро позиционирует как 2 логических проца )
                                            'NUM_CPUS');

-- текущая нагрузка на CPU и диски
select * From v$sysmetric where group_id = 2 and metric_name in ('Database CPU Time Ratio', 'Host CPU Utilization (%)', 'CPU Usage Per Sec',
                                                                 'Physical Reads Per Sec', 'Logical Reads Per Sec');

-- среднее значение нагрузки за последний час
select * from v$sysmetric_summary where group_id = 2 and metric_name in ('Database CPU Time Ratio', 'Host CPU Utilization (%)', 'CPU Usage Per Sec',
                                                                         'Physical Reads Per Sec', 'Logical Reads Per Sec');

-- нагрузказа последний час с поминутной разбивкой
-- DBA_HIST_SYSMETRIC_HISTORY
select * from v$sysmetric_history where group_id = 2 and metric_name in ('Database CPU Time Ratio', 'Host CPU Utilization (%)', 'CPU Usage Per Sec',
                                                                         'Physical Reads Per Sec', 'Logical Reads Per Sec') order by metric_name, begin_time desc;

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

-- использование CPU по сессиям по долгоиграющим запросам
select
   s.username,
   t.sid,
   s.serial#,
   s.sql_id,
   s.event,
   sum(value/100) as "cpu usage (seconds)",
   round((ratio_to_report(sum(value)) over ())*100, 2) as "pct, %",
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
group by username,t.sid,s.serial#, io.block_gets,
   io.consistent_gets,
   io.physical_reads,
   io.block_changes,
   io.consistent_changes,
   s.sql_id, s.event
order by 6 desc;


-- TopN query by cpu usage
select 
    s.sql_id AS sqlid,	
    s.plan_hash_value hv,
--    (select trim(dbms_lob.substr(t.sql_text, 4000)) from dba_hist_sqltext t where s.sql_id = t.sql_id) AS text,
--    trunc(w.begin_interval_time) AS tl,
    -- total in seconds
    sum(s.executions_delta)   AS e,
    round(sum(s.elapsed_time_delta) / 1e6, 4) AS ela_total,
    round(sum(s.cpu_time_delta)     / 1e6, 4) AS cpu_total,
    round(sum(s.iowait_delta)       / 1e6, 4) AS io_total,
    round(100 * sum(s.cpu_time_delta)   / greatest(sum(s.elapsed_time_delta), 1), 2) AS pct_cpu_usage,
    -- per exec in seconds
    round(sum(s.elapsed_time_delta)     / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS ela,
    round(sum(s.cpu_time_delta)         / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS cpu,
    round(sum(s.iowait_delta)           / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS io
from dba_hist_sqlstat s,
    dba_hist_snapshot w
where s.snap_id = w.snap_id
    and s.instance_number = w.instance_number
    and w.begin_interval_time >= timestamp'2020-12-07 10:00:00'
    and w.begin_interval_time <= timestamp'2020-12-07 10:30:00'
group by trunc(w.begin_interval_time),
    s.sql_id
    ,s.plan_hash_value
order by cpu_total desc;
