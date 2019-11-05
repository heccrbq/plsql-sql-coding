select sid, sql_id, sql_child_number, event from v$session where sid <> userenv('sid') and status = 'ACTIVE' and osuser = 'dvbykov';


SQL > SELECT /*abrakadabra*/ /*+gather_plan_statistics*/ ...


select sql_id, plan_hash_value, child_number, sql_text from v$sql where sql_fulltext like '%abrakadabra%';
select * from table(dbms_xplan.display_cursor(sql_id => 'd2mdtjp9dynrw'/*:sql_id*/, cursor_child_no => 3/*:sql_child_number*/, format => 'ALLSTATS LAST'));
select id, name, isdefault, value from v$sql_optimizer_env where sql_id = '3srshtyjrcghw'/*:sql_id*/ order by name;


-- Основные wait'ы с количеством вхождений.
select 
    trunc(sample_time), sql_id, sql_plan_hash_value, sql_child_number,
    session_state, event, wait_class, 
	count(1) wait_count, 
    sum(delta_read_io_requests) io_req,
    round(sum(tm_delta_cpu_time)/1e6, 4) cpu_time_sec,
    round(sum(tm_delta_db_time)/1e6, 4) db_time_sec,
    round((ratio_to_report(count(1)) over (partition by trunc(sample_time), sql_id, sql_child_number))*100, 2) as percent
from dba_hist_active_sess_history
where sql_id = '3srshtyjrcghw'/*:sql_id*/
	and sql_plan_hash_value = 3682407720/*:sql_plan_hash_value*/
--	and sql_child_number = 1/*:sql_child_number*/
    and trunc(sample_time) = trunc(sysdate)
group by session_state, event, wait_class, sql_id, sql_plan_hash_value, sql_child_number, trunc(sample_time)
order by trunc(sample_time) desc, sql_child_number, wait_count desc;


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
    decode(column_value, 0, 
		'SQL_ID  ' || sql_id || ', plan hash value  ' || plan_hash_value, 
		lpad(' ', depth) || operation) operation, options,
    object_owner, object_name, object_type,
    decode(column_value, 0, null, optimizer) optimizer,
    access_predicates, filter_predicates, --xmlroot(xmltype.createxml(other_xml), version '1.0" encoding="utf-8', standalone yes) other_xml,
    --
    cardinality, bytes, 
    decode(column_value, 0, null, cost) cost, cpu_cost, io_cost,
    time, temp_space
from dba_hist_sql_plan s,
    table(sys.odcinumberlist(0,1)) t
where t.column_value(+) >= s.id
    and sql_id = '3srshtyjrcghw'/*:sql_id*/
	and plan_hash_value = 3682407720/*:sql_plan_hash_value*/
order by plan_hash_value, s.id;


/**
 * =============================================================================================
 * Среднее время работы указанного запроса в каждом из снепшотов.
 * =============================================================================================
 * @param   sql_id   				Уникальный идентификатор запроса
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
    abs(extract(minute from(b.end_interval_time - b.begin_interval_time)) +
        extract(hour from(b.end_interval_time - b.begin_interval_time)) * 60 +
        extract(day from(b.end_interval_time - b.begin_interval_time)) * 24 * 60) minutes,
    a.executions_delta executions,
    round(a.elapsed_time_delta / 1000000 / greatest(a.executions_delta, 1), 4) "avg duration (sec)"
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
select s.sql_id, s.plan_hash_value, s.loads_delta loaded_versions,
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