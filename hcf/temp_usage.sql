https://www.sql.ru/forum/923969-1/create-index-disk-sorts
https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:10179466061600


=====================================================================================================================


есть понятие temporary tablespace - это тбс, куда временно пишутся данные, а после завершения команды/блока очищается.
Если говорить конкретно, то темтовый тбс используется для 
  - группировок (sort group by и hash group by) (group by включая rollup и тд)
  - сортировок (order by)
  - аналитических функций
  - сортировка перед MERGE JOIN
  - хранение hash таблицы во время соединения HASH JOIN  (onepass, multipass)
  - создание и ребилд индексов (вставка строки в таблицу с индексом заставляет его ребилдиться, поэтому обычный с виду insert в цикле может сожрать немало темпа)
  - global temporary table используют место из темпа
  
Есть один большой нюанс при работе с темпом - тем растет и не высвобождается пока запущенный sql_id не будет выполнен. 
То есть Будет разница, например, как запустить ребилд индексов, в цикле или каждая команда rebuild отдельно. 
В первом случае для ребилда 5 индексов потребуется темпа на 10 индексов (5 старых и 5 новых).
Во втором случае потребуется темп на 2 индекс( один старый и 1 новый в каждый комкретный момент), пока alter index не будет завершен.
То есть темп жрется в разрезе sql_id и sqlexecid.
  
Для темповых тбс используются свои вью:

select * from dba_tablespaces where contents = 'TEMPORARY';

-- дата файлы, закрепленные за темповыми тбс
1. dba_temp_files;
2. v$temp_space_header
3. v$tempfile

-- , выделенное и свободное место в тбс
1. dba_temp_free_space
2. v$sort_segment

1. v$sort_usage
2. v$active_session_history
3. v$sql_workarea_active

Регулярно стоит следить за тем, как потребляется темп. Так как если какая-то сессия его уж очень много его потребляет - это повод орбратить на него внимание.

-- Общая картина
select 
	-- temp tbs info --
    ss.tablespace_name
    ,t.contents
    ,t.segment_space_management
	-- temp memory usage --
    ,round(tf.total_space/1024/1024/1024, 3)  as "Total Temp space, Gb"
    ,round(tf.max_temp_size/1024/1024/1024,  3) as "Max Temp space, Gb"
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
            ,sum(tf.maxbytes) max_temp_size
        from dba_temp_files tf 
        where tf.tablespace_name = ss.tablespace_name) tf;


-- использование темпа по пользователям
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


select
    -- session info --
    s.username
    ,s.osuser
    ,s.sid
    ,s.serial#
    ,s.status
    ,s.program
    -- temp tbs info --
    ,su.tablespace
    ,su.contents
    ,su.segtype
	-- temp memory usage --
    ,round(su.blocks * t.block_size/1024/1024/1024, 3) as "Used Temp spaace, Gb"
    ,round((ratio_to_report(su.blocks)over())*100, 2)  as "pct used, %"
    -- process memory usage --
    ,round(swa.work_area_size/1024/1024, 3)    as "Allocated pga memory, Mb"
    ,round(swa.actual_mem_used/1024/1024, 3)   as "Used pga memory, Mb"
--    ,round(swa.tempseg_size/1024/1024/1024, 3) as "Used temp memory in workarea, Gb"
    -- sql info --
    ,s.sql_exec_id
    ,su.sql_id_tempseg sql_id
    ,sq.sql_text
    ,round(sq.elapsed_time/1e6,2) as "Elapsed time, sec"
    ,sq.program_id
    ,sq.program_line#
    -- transaction info --
    ,s.taddr
    ,t.used_urec
    ,t.used_ublk
    ,t.log_io
    ,t.phy_io
    ,t.cr_get
    ,t.cr_change
from v$sort_usage su
    left join dba_tablespaces t on tablespace_name = su.tablespace
    left join v$session s on s.saddr = su.session_addr
    left join v$sql sq on sq.sql_id = su.sql_id_tempseg
    left join v$sql_workarea_active swa on swa.sql_id = su.sql_id_tempseg and swa.sid = s.sid
    left join v$transaction t on t.addr = s.taddr
where s.osuser = 'AChernyshev'
order by 10 desc;

--память в разрезе категорий
select
    category                          as category, -- like SQL, PL/SQL, Other etc
    round(allocated/1024/1024, 2)     as allocated,
    round(used/1024/1024, 2)          as used,
    round(max_allocated/1024/1024, 2) as max_allocated
from
    v$process_memory pm
where exists 
    (select 0 from v$process p join v$session s on p.addr = s.paddr where p.pid = pm.pid  and s.sid = 5745);
	

-- используемая память сессией
select 
	sess.username  as username
    ,sess.sid      as session_id
    ,sess.serial#  as session_serial
    ,sess.program  as session_program
    ,sess.server   as session_mode
    ,name.name
    ,case when name like '%session%' then round(stat.value/1024/1024, 2) else stat.value end as "current memory (in MB)"
 from v$session    sess
    ,v$sesstat    stat
    ,v$statname   name
where sess.sid = stat.sid
    and stat.statistic# = name.statistic#
    and name.name   in ('session pga memory','session pga memory max','session uga memory','session uga memory max', 
                        'sorts (memory)', 'sorts (disk)', 'sorts (rows)',
                        'temp space allocated (bytes)', 'physical reads direct temporary tablespace', 'physical writes direct temporary tablespace',
                        'workarea memory allocated' , 'workarea executions - optimal', 'workarea executions - onepass' , 'workarea executions - multipass')
    and sess.sid   = 5745;
	

-- использование темпа в sql_id
with t as
(
    select 
        sql_id, sql_plan_line_id, max(p) pga, max(t) temp
    from 
        (select 
            sql_id, sql_plan_line_id, sum(pga_allocated) p, sum(temp_space_allocated) t
--        from dba_hist_active_sess_history  where sql_id = 'bpua850p63fpm' and snap_id between 76727 and 76731
		from v$active_session_history  where sql_id = 'bpua850p63fpm'
        group by sql_id, sql_plan_line_id, sample_id) 
    group by sql_id, sql_plan_line_id
)
    
select 
    -- sql plan --
    p.id
    ,lpad(' ', 4*depth) || p.operation operation
    ,p.options
    ,p.object_name
    ,p.object_type
    -- memory usage --
    ,round(p.temp_space/1024/1024/1024, 3) as "Estimated Temp usage, Gb"
    ,round(t.temp/1024/1024/1024, 3) as "Max used Temp space, Gb"
    ,round(t.pga/1024/1024/1024, 3)  as "Max used pga space, Gb"
--from dba_hist_sql_plan p left join t on p.id = t.sql_plan_line_id
from v$sql_plan p left join t on p.id = t.sql_plan_line_id
where p.sql_id = 'bpua850p63fpm'
order by 1;
