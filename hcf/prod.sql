/*
 * =================================================================================================
 * Алгоритмы поиска потенциально кривых запросов
 * =================================================================================================
 * 1. Анализ плана выполнения
 *   1.1. Если кардинальность при чтении индекса отличается от количества строк в индексе на 30%
 * 2. Анализ используемой памяти
 *   2.1. Анализ max_tempseg_size и количество проходов из v$sql_workarea
 *   2.2. Анализ 
 */
	




/*
 * совпадает ли схема индекса со схемой таблицы
 *
 */
select 
    table_owner, table_name, owner index_owner, index_name 
from all_indexes where owner <> table_owner and (owner = 'A4M' or table_owner = 'A4M');


/*
 * совпадает ли схема индекса со схемой таблицы
 *
 */
select * from dba_indexes where owner = 'A4M' and tablespace_name <> 'TBS_IDX' and table_name not like 'TTX$%' and table_name not like 'TDS$%';


/**
 * =================================================================================================
 * Список неиспользуемых индексов в планах выполнения с дополнительной DML статистикой
 * =================================================================================================
 * ALTER INDEX ... MONITORING USAGE
 *
 * v$index_usage_info
 * dba_index_usage
 * v$object_usage
 * user_object_usage
 * =================================================================================================
 * @param   index_owner   Схема/владелец индексов. Поиск будет осущетвлен по всем индексам схемы.
 *                        Стоить помнить, что индекс может лежать не в той же схеме, что и таблица.
 * =================================================================================================
 * Описание полей:
 *	- index_owner             : схема/владелец индекса
 *	- index_name              : наименование индекса
 *	- table_name              : наименование таблицы
 *	- uniqueness              : уникальность индекса
 *	- constraint_type         : тип констрейнта, который привязан к индексу
 *	- index_total_mb          : размер сегмента в Мб, выделенный под индекс
 *	- tbl_monitoring          : включен ли мониторинг на таблице, для которой создан индекс
 *	- idx_monitoring          : включен ли мониторинг индекса через ALTER INDEX MONITORING USAGE
 *  - index_used              : используется ли индекс, после включения на нём мониторинга
 *  - start_index_monitoring  : Дата и время включения мониторинга индекса 
 *	- last_index_used         : дата и время последнего использования индекса (заполнено, если
 *								в v$index_usage_info поле index_stats_enabled равно 1 (oracle 12.2+ ))
 *	- last_analyzed           : дата и время последнего сбора статистики
 *	- last_data_modification  : дата последней модификации данным (DML). Заполняется при ключенном 
 *                              на таблице мониторинге. 
 *                              Данное поле, также как и inserts, updates, deletes заполняются с 
 *                              момента последнего сбора статистики, то есть после last_analyzed
 *	- inserts                 : количество вставленных строк (insert) в таблицу
 *	- updates                 : количество измененных строк (update) в таблице
 *	- deletes                 : количество удаленных строк (delete) из таблицы
 *	- row_modified_per_minute : среднее количество модифицированных строк за период между last_analyzed 
 *                              и last_data_modification
 * =================================================================================================
 */
with settings as (
    select 'A4M' index_owner from dual
),
index_list_out_of_plan(index_owner, index_name) as (
    -- индекс не был найден в dba_hist_sql_plan и в v$sql_plan
    select 
        owner, object_name 
    from (
        select do.owner, do.object_name, sp.sql_id from dba_objects do 
            left join dba_hist_sql_plan sp on sp.object# = do.object_id where do.object_type = 'INDEX' and do.owner = (select index_owner from settings)
        union all
        select do.owner, do.object_name, sp.sql_id from dba_objects do 
            left join gv$sql_plan sp on sp.object# = do.object_id where do.object_type = 'INDEX' and do.owner = (select index_owner from settings)
    )
    group by owner, object_name 
    having max(sql_id) is null
),
index_list_tab_space as (
    -- добавляем к индексам инфу из таблицы и сегмента
    select
        di.owner index_owner, di.index_name, di.uniqueness, 
        dt.owner table_owner, dt.table_name, dt.last_analyzed, dt.monitoring,
        round(sum(bytes)/1024/1024, 3) index_total_mb
    from index_list_out_of_plan iloop
        inner join dba_indexes di on di.owner = iloop.index_owner and di.index_name = iloop.index_name
        inner join dba_tables dt on dt.owner = di.table_owner and dt.table_name = di.table_name
        inner join dba_segments ds on ds.owner = iloop.index_owner and ds.segment_name = iloop.index_name
    where dt.table_name like 'HCF_%'
    --where dt.table_name not like 'TTX$%' and dt.table_name not like 'TDS$%' --and dt.table_name not like 'HCF_%'
    group by di.owner, di.index_name, di.uniqueness, 
        dt.owner, dt.table_name, dt.last_analyzed, dt.monitoring
)

select
    ilts.index_owner, ilts.index_name, ilts.table_name, ilts.uniqueness, uc.constraint_type, ilts.index_total_mb,
    ilts.monitoring tbl_monitoring, ou.monitoring idx_monitoring, ou.used index_used, 
	to_date(ou.start_monitoring, 'mm/dd/yyyy hh24:mi:ss') start_index_monitoring, iu.last_used last_index_used, 
    ilts.last_analyzed, dm.timestamp last_data_modification, dm.inserts, dm.updates, dm.deletes, 
    round((dm.inserts + dm.updates + dm.deletes) / ((dm.timestamp - ilts.last_analyzed) * 1440)) row_modified_per_minute
from index_list_tab_space ilts
    left join dba_index_usage iu on iu.owner = ilts.index_owner and iu.name = ilts.index_name
    left join user_object_usage ou on ou.index_name = ilts.index_name and ou.table_name = ilts.table_name
    left join dba_tab_modifications dm on dm.table_owner = ilts.table_owner and dm.table_name = ilts.table_name and dm.partition_name is null
    left join user_constraints uc on uc.index_owner = ilts.index_owner and uc.index_name = ilts.index_name
order by index_total_mb desc nulls last;


/**
 * =================================================================================================
 * Поиск потенциально кривых запросов, использущих индексы за счет сравнения кардинальности с 
 * количеством строк в индексе.
 * =================================================================================================
 * @param   threshold   Пороговое значение в %, означающее на сколько процентов кардинальность 
 *                      должна быть меньше количества строк в индексе. 
 *  					Теоретически это означает какое количество строк в % поднимает индекс.
 *                      Эмпирически считается, что при threshold > 10% запрос следует оптимизировать
 * =================================================================================================
 * Описание полей:
 *	- sql_id          	: sql_id запроса
 *  - plan_hash_value 	: хэш значение плана выполнения
 *  - object_name 		: наименование объекта, где хранится выполняемый код данного sql_id
 *  - program_line# 	: срока кода в object_name, где выполняется данный sql_id
 *  - io_pct 			: среднее %-ное соотношение времени выполнения и времени io в данном sql_id
 *  - io_time 			: среднее время IO текущего sql_id (в секундах) с даным row source
 *  - operation 		: операция доступпа к данным
 *  - options 			: опция операции
 *  - object_owner 		: владелец объекта
 *  - object_name 		: наименование объекта, чтение которого производится
 *  - cardinality 		: кардинальность операции из плана выполнения
 *  - ind_num_rows 		: количеств строк в индексе на основе статистики
 *  - distinct_keys 	: количество уникальных значений (пар значений) в индексе
 *  - tab_num_rows 		: количество строк в таблице на основе статистики
 *  - access_predicates : предикаты индексного доступа
 *  - filter_predicates : предикаты фильтрации данных
 * =================================================================================================
 */
with settings as (
    select 0.3 /*30%*/ threshold from dual
)
select 
    s.sql_id, 
    s.plan_hash_value, 
--    o.object_name, 
--    s.program_line#, 
    round( 100 * s.user_io_wait_time/elapsed_time, 2) io_pct, 
    round(s.user_io_wait_time / greatest(s.executions,1) / 1e6) io_time,
    pl.operation, 
    pl.options, 
--    pl.object_owner, 
    pl.object_name, 
    pl.cardinality,
    ind.num_rows ind_num_rows, 
    ind.distinct_keys , 
    tab.num_rows tab_num_rows,
    pl.access_predicates, 
    pl.filter_predicates 
from v$sql_plan pl
    join user_indexes ind on ind.index_name = pl.object_name
    join user_tables tab on tab.table_name = ind.table_name
    left join v$sql s on s.sql_id = pl.sql_id 
					 and s.plan_hash_value = pl.plan_hash_value 
					 and s.child_number = pl.child_number
    left join user_objects o on o.object_id = s.program_id
    cross join settings
where pl.operation = 'INDEX' 
    and pl.options in ('RANGE SCAN', 'SKIP SCAN')
    and pl.object_owner = 'A4M'
    and pl.cardinality / ind.num_rows > settings.threshold
	and ind.num_rows <> 0
order by cardinality desc;


/**
 * =================================================================================================
 * Список таблиц, которые надо помувать. 
 * Теоретически занимаемый данными размер может сильно отличаться от размера сегмента.
 * =================================================================================================
 * @param   threshold   Пороговое значение в %, означающее на сколько теоретически занимаемое
 *                      таблицей место отличается от размера сегмента
 * =================================================================================================
 * Описание полей:
 *	- table_name       : наименование таблицы
 *  - compression      : является ли таблица сжатой
 *  - last_analyzed    : дата последнего сбора статистики
 *  - allocated_blocks : количество выделенных сегменту блоков
 *  - formatted_blocks : количество используемых таблицей блоков (отформатированных)
 *  - allocated_space  : количество выделенного дискового пространства (в байтах) сегменту
 *  - used_space       : количество используемого дискового пространства (в байтах) таблицей
 *  - threshold        : % соотношение используемого и выделенного дискового пространства
 * =================================================================================================
 */
with settings as (
    select 0.3 /*30%*/ threshold from dual
)
select
    sbq.*
    ,round(100 * (allocated_space/coalesce(nullif(used_space,0),1) - 1),2) threshold
from
    (select 
        t.table_name
        ,t.last_analyzed
        ,s.allocated_blocks
        ,t.blocks formatted_blocks
        ,s.allocated_space
        ,t.avg_row_len * t.num_rows used_space
    from user_tables t 
        left join
            (select
                segment_name
                ,sum(s.blocks) allocated_blocks
                ,sum(s.bytes) allocated_space
            from user_segments s
            group by segment_name) s
        on s.segment_name = t.table_name)sbq        
    cross join settings
where allocated_space/coalesce(nullif(used_space,0),1) - 1 >= settings.threshold
    and (/*allocated_blocks <> 256 and */coalesce(used_space,0) > 0)
    and not (table_name like 'TDS$%' or table_name like 'TTX$%')
order by allocated_space desc;


/**
 * =================================================================================================
 * Размер занимаемого места таблицей и зависимыми объектами: индексы, лобы
 * =================================================================================================
 * @param   owner        Владелец (схема) таблицы
 * @param   table_name   Наименование таблицы
						
 * =================================================================================================
 * Описание полей:
 *	- object_name : наименование объекта (таблица, индекса, лоб и тд)
 *  - gbytes      : размер выделенного сегмента под объект (в гигабайтах)
 *  - blocks      : количество блоков, занимаемых сегментом
 *  - extents     : количество экстентов, занимаемых сегментом
 * =================================================================================================
 */
with settings as (
    select 'A4M' owner, column_value table_name from table(sys.odcivarchar2list('TENTRY'))
),
-- список зависимых объектов
object_list(owner, obj, type) as (
    select owner, table_name, 'TABLE' from dba_tables natural join settings
    union all
    select owner, index_name, 'INDEX' from dba_indexes natural join settings where index_type <> 'LOB'
    union all
    select owner, segment_name, 'LOBSEGMENT' from dba_lobs natural join settings
    union all
    select owner, index_name, 'LOBINDEX' from dba_lobs natural join settings
),
-- определение занимаемого места зависимым объектов
object_size(owner, obj, type, bytes, blocks, extents) as (
    select
        owner, obj, type,
        bytes, blocks, extents
    from (
        -- Tables
        select ol.*, s.bytes, s.blocks, s.extents
        from dba_segments s 
            join object_list ol on ol.owner = s.owner and ol.obj = s.segment_name
        where (ol.type = 'TABLE' and s.segment_type in ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION'))
            or (ol.type = 'INDEX' AND s.segment_type in ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION'))
            or (ol.type in ('LOBSEGMENT', 'LOBINDEX') and s.segment_type = ol.type))
)

-- форматирование результатов
select
    case when obj is null then coalesce(type,'TOTAL') || ':' end || lpad(obj, length(obj) + 4) "Object",
    round(sum(bytes)/1024/1024/1024,3) "Disk space, Gbytes", sum(blocks) AS "Blocks", sum(extents) AS "Extents"
from object_size
group by grouping sets ((owner, obj, type), (type), ())
order by decode(type, 'TABLE', 1, 'INDEX', 2, 'LOBSEGMENT', 3, 4), owner nulls first, obj;



-- использование темпа
select --+parallel(8)
            ash.sql_id,
            ash.sql_plan_hash_value,
            ash.sql_plan_line_id,
            round(max(temp_space_allocated)/1024/1024, 3) tmp,
            round(max(pga_allocated)/1024/1024, 3) pga
        from dba_hist_active_sess_history ash where sample_time >= date'2021-06-09'
        group by ash.sql_id,
            ash.sql_plan_hash_value,
            ash.sql_plan_line_id
        order by tmp desc nulls last;
		
select * from v$sql_workarea order by max_tempseg_size desc nulls last;




-- изучение access_predicates индексного доступа по sql_id
with settings as (
    select 'A4M' index_owner from dual
)

select 
    sql_id, plan_hash_value, child_number, 
    id, options, index_owner, index_name, table_name,
    sum(out_of_access_predicates) || ' of ' || count(out_of_access_predicates) column_usage, 
    listagg(column_name || '(' || out_of_access_predicates || ')', ', ')within group(order by column_position) column_usage_details,
    access_predicates
from (
    select 
        sql_id, plan_hash_value, child_number, 
        sp.id, sp.options, ic.index_owner, ic.index_name, ic.table_name, sp.access_predicates, sp.filter_predicates, ic.column_name, ic.column_position,
        case when sp.access_predicates like 
            case when sp.object_alias not like ic.table_name || '@%' then '%"' || regexp_substr(sp.object_alias,'^[^@]+') || '".'  else '%' end 
            || '"' || ic.column_name || '"%' then 1 else 0 end out_of_access_predicates
    from v$sql_plan sp
        inner join dba_ind_columns ic on ic.index_owner = sp.object_owner and ic.index_name = sp.object_name
    where sp.operation = 'INDEX' and sp.object_owner = (select index_owner from settings)
--        and sp.sql_id = '0046n1xru5fdq'
)
group by sql_id, plan_hash_value, child_number, id, options, index_owner, index_name, table_name, access_predicates
having sum(out_of_access_predicates) <> count(out_of_access_predicates)





1. Использование регулярных выражений. Лучше заменить на substr+instr. регулярка работает в 40 раз дольше.
2. Использование nullif. Nuliif разворачивается в case when и поэтому если первым аргументов тяжелая not deterministic функция, то может работать долго.

	----- Current SQL Statement for this session (sql_id=dhsh84asrhd9y) -----
	select nullif(dummy, 'Y') from dual
	
	Final query after transformations:******* UNPARSED QUERY IS *******
	SELECT CASE "DUAL"."DUMMY" WHEN 'Y' THEN NULL ELSE "DUAL"."DUMMY" END  "NULLIF(DUMMY,'Y')" FROM "SYS"."DUAL" "DUAL"
3. Посмотреть неявное преобразование типов в access и filter predicates.
