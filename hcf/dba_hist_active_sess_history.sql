/**
 * =============================================================================================
 * Усредненные показатели работы запроса за определенный промежуток времени в разрезе дня
 * =============================================================================================
 * @param   sql_id (VARCHAR2)   Уникальный идентификатор запроса
 * @param   btime  (DATE)       Начало периода
 * @param   etime  (DATE)       Окончание периода
 * =============================================================================================
 * Описание полей:
 *  - text  : текст запроса (SQL Text)
 *  - sqlid : уникальный идентификатор запроса (SQL id)
 *  - tl    : дата и время начала снепшота, в котором был замечен запрос (Timeline)
 *  - e     : количество запусков в рамках группировки (Executions)
 *  - pct_e : процентное соотношение запусков по разным планам выполнения по дню
 *  - ela_t : общее время выполнения, затраченное на все запуски запроса (Elapsed Time (s) Total)
 *  - ela   : Среднее время выполнения запроса в секундах (Avg Elapsed Time (s) per Exec) 
 *  - cpu   : Среднее время использование процессорных ресурсов (Avg CPU Time (s) per Exec)
 *  - io    : Среднее время, затраченное на операции ввода-вывода (Avg I/O Time (s) per Exec)
 *  - cc    : Среднее время, затраченное на события конкуренции в секундах (Avg Concurrency Wait Time (s))
 *  - app   : Среднее время, затраченное на ожидания приложением в секундах (Avg Application Wait Time (s))
 *  - plsql : Среднее время выполнения логики PL/SQL движком в секундах (Avg PL/SQL Execution Time (s))
 *  - java  : Среднее время выполнения логики JVM в секундах (Avg Java Execution Time (s))
 *  - disk  : Среднее количество блоков, вычитанных с диска (Avg Physical Reads per Exec (number of blocks))
 *  - lio   : Среднее количество блоков, вычитанных из памяти в режимах cr и cu (Avg Logical Reads per Exec (number of buffers))
 *  - r     : Среднее количество строк, возвращенное запросом (Avg Rows Processed per Exec)
 *  - pc    : Среднее количество parse calls (Avg Parse Calls)
 *  - px    : Среднее количество параллелей, используемых запросом (Avg PX Servers)
 * =============================================================================================
 */
with source as (
    select '7qfg0j2h5z617' sql_id, trunc(sysdate) - 30 btime, trunc(sysdate) + 1 etime from dual
 )
select 
--    (select trim(dbms_lob.substr(t.sql_text, 4000)) from dba_hist_sqltext t where s.sql_id = t.sql_id) AS text,
--    s.sql_id AS sqlid,
    s.plan_hash_value hv,
    trunc(w.begin_interval_time) AS tl,
    sum(s.executions_delta) AS e,
    round(ratio_to_report(sum(s.executions_delta))over(partition by s.sql_id, trunc(w.begin_interval_time)) * 100, 2) pct_e,
    round(sum(s.elapsed_time_delta)/1e6, 4) ela_t,
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





/**
 * =============================================================================================
 * Время выполнения запроса по версии HIST ASH в разрезе SQL_EXEC_ID
 * =============================================================================================
 * @param   sql_id (VARCHAR2)   Уникальный идентификатор запроса
 * @param   btime  (DATE)       Начало периода
 * @param   etime  (DATE)       Окончание периода
 * =============================================================================================
 * Описание полей:
 *  - sid_serial      : SID и SERIAL сессии
 *  - sql_exec_id     : идентификатор запуска запроса
 *  - plan_hash_value : хэш значение плана выполнения
 *  - snap_range      : период снепшотов, в котором был выполнен запрос
 *  - sql_exec_start  : время начала выполнения конкретного запуска запроса
 *  - sql_exec_stop   : время окончания выполнения конкретного запуска запроса
 *  - sql_exec_diff   : разница в секундах между времени начала и окончания работы запуска 
 *  - db_time         : время работы базы данных, затраченное на запрос (в секундах)
 *  - cpu_time        : время работы процессора, затраченное на запрос (в секундах)
 *  - read            : количество прочитанных данных (в мегабайтах)
 *  - write           : количество записанных данных (в мегабайтах)
 *  - wait_count      : общее количество строк выполнения в ASH в разрезе SQL_EXEC_ID.
                        умножая на 10, можно получить примерное время работы в секундах
 *  - parse           : количество вхождений в ASH, относительно парса запроса
 *  - hard_parse      : количество вхождений в ASH, относительно полного парса запроса
 *  - sql             : количество вхождений в ASH, относительно выполнения запроса
 *  - plsql           : количество вхождений в ASH, относительно выполнения PL/SQL кода
 *  - java            : количество вхождений в ASH, относительно выполнения Java кода
 *  - cursor_close    : количество вхождений в ASH, относительно выполнения закрытия курсора
 * =============================================================================================
 */
with source as (
    select '6hjs0624rwqyy' sql_id, trunc(sysdate) - 30 btime, sysdate etime from dual
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





/**
 * =============================================================================================
 * Поиск long-running запросов по сессии за промежуток времени в истории
 * =============================================================================================
 * @param   sid      (NUMBER)   Уникальный идентификатор сессии
 * @param   serial#  (NUMBER)   Уникальный номер сессии
 * @param   bsnap_id (NUMBER)   Уникальный идентификатор снепшота начала выполнения
 * @param   esnap_id (NUMBER)   Уникальный идентификатор снепшота окончания выполнения
 * =============================================================================================
 * Описание полей:
 *  - sql_id   : уникальный идентификатор запроса (SQL id)
 *  - unq_run  : количество уникальных запусков запроса (EXEC_ID + EXEC_START)
 *  - rowcount : количество ASH эвентов, найденных в истории для запроса
 *  - db_time  : время работы базы данных, затраченное на запрос (в секундах)
 *  - cpu_time : время работы процессора, затраченное на запрос (в секундах)
 *  - sql_text : текст запроса, взятый из истории
 * =============================================================================================
 */
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





/**
 * =============================================================================================
 * Сбор информации о событиях ожидания по конкретному запуску запроса
 * =============================================================================================
 * @param   sql_id      (VARCHAR2)   Уникальный идентификатор запроса
 * @param   sql_exec_id (NUMBER)     Номер выполнения запроса
 * @param   bsnap_id    (NUMBER)     Уникальный идентификатор снепшота начала выполнения
 * @param   esnap_id    (NUMBER)     Уникальный идентификатор снепшота окончания выполнения
 * =============================================================================================
 * Описание полей:
 *  - sql_id            : уникальный идентификатор запроса (SQL id)
 *  - plan_hash_value   : хэш значение плана выполнения
 *  - cn                : номер дочернего запроса (child number)
 *  - session_state     : состояние сессии
 *  - event             : событие ожидания
 *  - wait_class        : класс события ожидания
 *  - wait_count        : количество событий ожидания
 *  - time_waited_micro : среднее время, за которое выполняется данное событие
 *  - stddev_micro      : стандартное отклонение от среднеме времени выполнения события
 *  - avg_blocks        : среднее количество блоков, которое поднимается с диска за событие
 *  - io_req            : количество запросов на чтение и запись отправляемых дисковой подсистеме
 *  - db_time           : время работы субд, затраченное на выполнения запроса
 *  - cpu_time          : время работы процессора, затраченное на выполнения запроса
 *  - pct_used          : % соотношение времени выполнени конкретного эвента по отношению 
                          к общему времени выполнения
 * =============================================================================================
 */
with source as (
    select '36h9grzu8qscn' sql_id, 16777239 sql_exec_id, 98870 bsnap_id, 98870 esnap_id from dual
)
select
    ash.sql_id, 
    ash.sql_plan_hash_value plan_hash_value,
    ash.sql_child_number cn,
    ash.session_state, 
    ash.event, 
    ash.wait_class,
	count(1) wait_count, 
    round(avg(ash.time_waited)) time_waited_micro,
    round(stddev(ash.time_waited)) stddev_micro,
    round(decode(ash.event, 'db file sequential read', avg(p3),
                            'db file parallel read',   avg(p2),
                            'direct path read temp',   avg(p3))) avg_blocks,
    sum(ash.delta_read_io_requests + ash.delta_write_io_requests) io_req,
    round(sum(ash.tm_delta_db_time)/1e6, 2) db_time,
    round(sum(ash.tm_delta_cpu_time)/1e6, 2) cpu_time,
    round((ratio_to_report(sum(ash.tm_delta_db_time)) over (partition by ash.sql_id, ash.sql_plan_hash_value, ash.sql_child_number)) * 100, 2) as pct_used
from source s 
    join dba_hist_active_sess_history ash on ash.sql_id = s.sql_id 
                                         and ash.sql_exec_id = s.sql_exec_id
                                         and ash.snap_id between s.bsnap_id and s.esnap_id
group by ash.sql_id, 
    ash.sql_plan_hash_value, 
    ash.sql_child_number,
    ash.session_state, 
    ash.event, 
    ash.wait_class
order by ash.sql_child_number, 
    wait_count desc;





/**
 * =============================================================================================
 * Запрос генерации плана выполнения, полученнего из HIST'а
 * =============================================================================================
 * @param   sql_id          (VARCHAR2)   Идентификатор запроса
 * @param   plan_hash_value (NUMBER)     План выполнения запроса
 * @param   format          (VARCHAR2)   Формат генерации отчета
 * =============================================================================================
 * Описание полей:
 *  - file#  : имя сгенерированного отчета
 *  - output : содержание отчета
 */
with source as (
    select '1vfqf2sv20sns' sql_id, 4231107709 plan_hash_value, 'basic +outline +note' format from dual
)
select
    'EXEC_PLAN_AWR_' || lower(d.name) || '_' || s.sql_id || '_' || s.plan_hash_value || '.txt' file#,
    dbms_xmlgen.convert(xmlagg(xmlelement(output, t.plan_table_output || chr(10)) order by rownum).extract('//text()').getclobval(),1) output
from source s,
    v$database d,
    table(dbms_xplan.display_awr(sql_id          => s.sql_id,
                                 plan_hash_value => s.plan_hash_value,
                                 db_id           => d.dbid,
                                 format          => s.format)) t
group by d.name,
    s.sql_id,
    s.plan_hash_value;



















/**
 * =============================================================================================
 * Среднее время работы указанного запроса в каждом из снепшотов.
 * =============================================================================================
 * @param   sql_id   	                Уникальный идентификатор запроса
 * @param   sql_plan_hash_value		Хэш значение плана выполнения искомого запроса
 * =============================================================================================
 * Описание полей:
 *	- inst_id : номер инстанса
 *  - snap_id : уникальный номер снепшота
 *  - btime : дата и время начала снепшота, в котором был замечен запрос
 *  - minutes : длительность снепшота
 *  - executions : как часто выполнялся запрос, в течение <minutes>
 *  - avg duration (sec) : время выполнения (elapsed time) запроса
 * =============================================================================================
 */
select 
    a.instance_number inst_id,
    a.snap_id,
    a.plan_hash_value,
    to_char(b.begin_interval_time, 'dd-mon-yy hh24:mi') btime,
    extract(minute from (end_interval_time - begin_interval_time)) minutes,
    a.executions_delta executions,
    round(a.elapsed_time_delta / 1e6 / greatest(a.executions_delta, 1), 4) "Avg Duration (sec) per exec"
from   dba_hist_sqlstat  a,
       dba_hist_snapshot b
where a.sql_id = '3srshtyjrcghw'/*:sql_id*/
--	and plan_hash_value = 3682407720/*:sql_plan_hash_value*/
    and a.snap_id = b.snap_id
    and a.instance_number = b.instance_number
order by snap_id desc,
    a.instance_number;


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
    ao.object_name,
    ash.current_obj#,
    ash.event,
    count(1) wait_count,
    sum(delta_read_io_requests) io_req,
    round(sum(tm_delta_cpu_time)/1e6, 4) cpu_time_sec,
    round(sum(tm_delta_db_time)/1e6, 4) db_time_sec,
    round(sum(count(1))over(partition by sql_plan_line_id) / sum(count(1))over() * 100, 2) percent_per_line, 
    round(sum(count(1))over(partition by sql_plan_line_id, session_state) / sum(count(1))over(partition by sql_plan_line_id) * 100, 2) percent_per_line_state, 
    round(sum(count(1))over(partition by sql_plan_line_id, session_state, event) / sum(count(1))over(partition by sql_plan_line_id, session_state) * 100, 2) percent_per_line_state_event
from dba_hist_active_sess_history ash
    , all_objects ao
where ash.sql_id = '356xmrh0vbtnj'/*:sql_id*/
--	and ash.sql_plan_hash_value = 3682407720/*:sql_plan_hash_value*/
--	and ash.sql_child_number = 0 /*:sql_child_number*/
    and ao.object_id(+) = ash.current_obj#
    and sample_time >= trunc(sysdate)
group by ash.session_state,
    ash.sql_opname,
    ash.sql_plan_line_id,
    ash.sql_plan_operation,
    ash.sql_plan_options,
    ao.object_name,
    ash.current_obj#,
    ash.event
order by ash.sql_plan_line_id, min(sample_id);


/**
 * =============================================================================================
 * План выполнения запроса.
 * =============================================================================================
 * @param   sql_id   				Уникальный идентификатор запроса
 * @param   sql_plan_hash_value		Хэш значение плана выполнения искомого запроса
 * =============================================================================================
 * Описание полей:
 * 	- id : номер шага в плане выполнения
 *  - operation : операция
 *  - options : тип операции
 *  - object_owner : владелец объекта
 *  - object_name : наименование объекта
 *  - object_type : тип объекта
 *	- optimizer : опция оптимизатора (ALL_ROWS | FIRST ROWS)
 *	- access_predicates : предикаты доступа по индексу
 *  - filter_predicates : предикаты фильтрации данных
 * 	- cardinality : количество строк, которое оптимизатор ожиданиет получить в результате выполнения
 *					операции <operation> + <options> над объектом <object_name>.
 *	- bytes :  количество байт, которое оптимизатор ожидает вернуть в результате выполнения операций
 * 	- cost : стоимость выполения шага
 *	- cpu_cost : стоимость использования процессорных ресурсов. Здесь cpu_cost равен количеству
 *				 машинных циклов, необходимых для выполнения шага
 *	- io_cost : стоимость выполнения LIO
 *	- time : ?
 *	- temp_space : оценка оптимизатора по использованию темповой оперативной памяти
 * =============================================================================================
 */
select
    decode(column_value, 0, null, id) id,
    max(depth)over(partition by sql_id, plan_hash_value) - decode(column_value, 0, null, depth) depth,
    decode(column_value, 0, 
		'SQL_ID  ' || sql_id || ', plan hash value  ' || plan_hash_value, 
		lpad(' ', depth) || operation) operation, options,
    object_owner, object_name, object_type,
    decode(column_value, 0, null, optimizer) optimizer,
	-- В хисте не хранятся предикаты: поля пустые
    -- access_predicates, filter_predicates,
	-- xmlroot(xmltype.createxml(other_xml), version '1.0" encoding="utf-8', standalone yes) other_xml,
    --
    cardinality, bytes, 
    decode(column_value, 0, null, cost) cost, cpu_cost, io_cost,
    time, temp_space
from dba_hist_sql_plan s,
    table(sys.odcinumberlist(0,1)) t
where t.column_value(+) >= s.id
    and sql_id = '3srshtyjrcghw'/*:sql_id*/
	and plan_hash_value = 3682407720/*:sql_plan_hash_value*/
order by plan_hash_value, s.id, t.column_value;


/**
 * =============================================================================================
 * Статистика работы запроса в конкретном снепшоте
 * =============================================================================================
 * @param   sql_id   	Уникальный идентификатор запроса
 * @param   snap_id		Уникальный номер снепшота
 * =============================================================================================
 * Описание полей:
 *	- sql_id : уникальный идентификатор запроса
 *  - plan_hash_value : хэш значение плана выполнения искомого запроса
 *  - loaded_versions : количество загруженных версий запроса
 *  - elapsed_time_sec : время выполнения конкретного <sql_id> в данном снепшоте в секундах.
 *						 Стоит учесть, что это суммарное время выполнения всех <executions>.
 *						 ELAPSED_TIME = CPU_TIME + IO_TIME + IDLE_TIME
 *  - cpu_time_sec : процессорное время работы в секундах конкретного <sql_id> в данном снепшоте.
 *  - concurrency_wait_time_sec : время в секундах, потраченное на события ожидания.
 *								  Здесь учитывается время на защелки, блокировки и др.
 *	- user_io_wait_time_sec : время в секундах, затраченное на операции физического и логического
 *							  чтения в режимах consistent mode и current mode (LIO).
 *	- application_wait_time : время ожидания (в миллисекундах), затраченное на события IDLE
 *	- disk_reads : количество прочтенных блоков с диска
 *	- buffer_gets : количество прочтенных блоков с буферного кэша. Включает в себя и поднятные 
 *					блоки с диска <disk reads>
 * 	- direct_writes : ?
 * 	- rows_processed : количество обработанных строк
 * 	- fetches : количество зафетченных строк оператором (то, сколько видит клиент)
 *	- end_of_fetch_count : ?
 * 	- executions : количество выполнений запроса в рамках снепшота
 *	- parse_calls : колиство хард парса запроса
 * 	- px_servers_executions : количество параллелей, в которое был запущен запрос
 * =============================================================================================
 */
select s.snap_id, s.sql_id, s.plan_hash_value, s.loads_delta loaded_versions,
    round(s.elapsed_time_delta / 1e6, 4) elapsed_time_sec, 
	round(s.cpu_time_delta / 1e6, 4) cpu_time_sec, --ss.avg_hard_parse_time, 
	round(s.ccwait_delta / 1e6, 4) concurrency_wait_time_sec, 
	round(s.iowait_delta / 1e6, 4) user_io_wait_time_sec, s.apwait_delta application_wait_time,
    s.disk_reads_delta disk_reads, s.buffer_gets_delta buffer_gets, s.direct_writes_delta direct_writes, --s.direct_reads, 
    s.rows_processed_delta rows_processed, s.fetches_delta fetches, s.end_of_fetch_count_delta end_of_fetch_count,
    s.executions_delta executions, s.parse_calls_delta parse_calls, s.px_servers_execs_delta px_servers_executions
from dba_hist_sqlstat s 
where s.sql_id = '3srshtyjrcghw'/*:sql_id*/
    and snap_id = 65103/*:snap_id*/;
	
	
	
select 
    nullif(sp.id + nvl(t.column_value,0), 0) id, sp.parent_id, nullif(sp.depth - 1, -1) depth, 
    decode(t.column_value, 0, 
        -- sql_id, hv = plan hash value, ela = elapsed time per seconds, disk = physical read, lio = consistent gets (cr + cu), r = rows processed
		'SQL_ID = ' || s.sql_id || ', hv = ' || s.plan_hash_value ||
        ', ela = ' || replace(round(s.elapsed_time_delta / greatest(s.executions_delta, 1) / 1e6, 2), ',', '.') || 
		', cpu = ' || replace(round(s.cpu_time_delta / greatest(s.executions_delta, 1) / 1e6, 2), ',', '.') ||
		', io = ' || replace(round(s.iowait_delta / greatest(s.executions_delta, 1) / 1e6, 2), ',', '.') ||
		', disk = ' || s.disk_reads_delta || ', lio = ' || s.buffer_gets_delta || ', r = ' || s.rows_processed_delta,
        --
        lpad(' ', 4*depth) || sp.operation || nvl2(sp.optimizer, '  Optimizer=' || sp.optimizer, null) ||
        nvl2(sp.options, ' (' || sp.options || ')', null) || 
        nvl2(sp.object_name, ' OF ''' || nvl2(sp.object_owner, sp.object_owner || '.', null) || sp.object_name || '''', null) ||
        decode(sp.object_type, 'INDEX (UNIQUE)', ' (UNIQUE)') ||
        '  (Cost=' || cost || ' Card=' || sp.cardinality || ' Bytes=' || bytes || ')') sqlplan,
    (select count(1) from dba_hist_active_sess_history ash 
    where ash.instance_number = s.instance_number and ash.snap_id = w.snap_id and ash.sql_id = sp.sql_id and ash.sql_plan_hash_value = sp.plan_hash_value and ash.sql_plan_line_id = sp.id) ash_wait_count
--    ,sp.access_predicates
--    ,sp.filter_predicates
from dba_hist_sqlstat s
    join dba_hist_sql_plan sp on sp.sql_id = s.sql_id and sp.plan_hash_value = s.plan_hash_value
    join dba_hist_snapshot w on w.snap_id = s.snap_id and w.instance_number = s.instance_number
    left join table(sys.odcinumberlist(0,1)) t on t.column_value >= sp.id
where s.sql_id = '3cks5v1jgxctx'
    and w.begin_interval_time >= trunc(sysdate)
order by w.snap_id, s.plan_hash_value, sp.id, t.column_value;
	
	
	
	
<other_xml>
    <info type="db_version">12.2.0.1</info>
    <info type="parse_schema">
        <![CDATA["SYS"]]>
    </info>
    <info type="plan_hash_full">1618302044</info>
    <info type="plan_hash">3326593961</info>
    <info type="plan_hash_2">4244282476</info>
    <peeked_binds>
        <bind pos="1" dty="1" csi="873" frm="1" mxl="128">535953</bind>
        <bind pos="2" dty="1" csi="873" frm="1" mxl="128">55544c5f5245434f4d505f434f4d50494c4544</bind>
        <bind pos="3" dty="2" pre="0" scl="0" mxl="22">c102</bind>
    </peeked_binds>
    <info type="adaptive_plan" note="y">yes</info>
    <outline_data>
        <hint><![CDATA[IGNORE_OPTIM_EMBEDDED_HINTS]]></hint>
        <hint><![CDATA[OPTIMIZER_FEATURES_ENABLE('12.2.0.1')]]></hint>
        <hint><![CDATA[DB_VERSION('12.2.0.1')]]></hint>
        <hint><![CDATA[ALL_ROWS]]></hint>
        <hint><![CDATA[OUTLINE_LEAF(@"SEL$1")]]></hint>
        <hint><![CDATA[INDEX_RS_ASC(@"SEL$1" "U"@"SEL$1" ("USER$"."NAME"))]]></hint>
        <hint><![CDATA[INDEX(@"SEL$1" "O"@"SEL$1" ("OBJ$"."OWNER#" "OBJ$"."NAME" "OBJ$"."NAMESPACE" "OBJ$"."REMOTEOWNER" "OBJ$"."LINKNAME" "OBJ$"."SUBNAME" "OBJ$"."TYPE#" "OBJ$"."SPARE3" "OBJ$"."OBJ#"))]]></hint>
        <hint><![CDATA[INDEX(@"SEL$1" "PO"@"SEL$1" ("PARTOBJ$"."OBJ#"))]]></hint>
        <hint><![CDATA[LEADING(@"SEL$1" "U"@"SEL$1" "O"@"SEL$1" "PO"@"SEL$1")]]></hint>
        <hint><![CDATA[USE_NL(@"SEL$1" "O"@"SEL$1")]]></hint>
        <hint><![CDATA[USE_NL(@"SEL$1" "PO"@"SEL$1")]]></hint>
        <hint><![CDATA[NLJ_BATCHING(@"SEL$1" "PO"@"SEL$1")]]></hint>
    </outline_data>
    <display_map>
        <row op="1" dis="1" par="0" prt="0" dep="1" skp="0"/>
        <row op="2" dis="2" par="1" prt="0" dep="2" skp="0"/>
        <row op="3" dis="2" par="2" prt="0" dep="2" skp="1"/>
        <row op="4" dis="3" par="2" prt="0" dep="3" skp="0"/>
        <row op="5" dis="3" par="3" prt="0" dep="3" skp="1"/>
        <row op="6" dis="4" par="3" prt="0" dep="4" skp="0"/>
        <row op="7" dis="5" par="4" prt="0" dep="5" skp="0"/>
        <row op="8" dis="6" par="3" prt="0" dep="4" skp="0"/>
        <row op="9" dis="6" par="2" prt="0" dep="2" skp="1"/>
        <row op="10" dis="7" par="2" prt="0" dep="3" skp="0"/>
        <row op="11" dis="8" par="1" prt="0" dep="2" skp="0"/>
    </display_map>
</other_xml>




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






with source as 
(
    select '3x647rx85y5a7' sql_id, 398501937 plan_hash_value, 16777218 sql_exec_id, 85529 snap_id_from, 85546 snap_id_to from dual
),
settings as 
(
    select 0 enable_events from dual
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
    null pga
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
    null pga
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
    ash.pga
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
            round(max(pga_allocated)/1024/1024, 3) pga
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
    round(max(pga_allocated)/1024/1024, 3) pga
from ash
where exists (select 0 from settings where enable_events = 1)
group by ash.sql_id,
    ash.sql_plan_hash_value,
    ash.sql_plan_line_id,
    ash.session_state, 
    ash.event
order by id nulls first, parent_id, sqlplan desc;















-- undo + hist

with source as 
(
    select '3x647rx85y5a7' sql_id, 398501937 plan_hash_value, 16777219 sql_exec_id, 86105 snap_id_from, 86159 snap_id_to from dual
),
settings as 
(
    select 0 enable_events from dual
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

