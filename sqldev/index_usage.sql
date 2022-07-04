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
 * @param   depth         Глубина использования индексов. В результирующей выборке появляются все 
 *                        индексы, которые старшне укащанной глубины от sysdate
 * =================================================================================================
 * Описание полей:
 *  - index_owner             : схема/владелец индекса
 *  - index_name              : наименование индекса
 *  - table_name              : наименование таблицы
 *  - uniqueness              : уникальность индекса
 *  - constraint_type         : тип констрейнта, который привязан к индексу
 *  - index_total_mb          : размер сегмента в Мб, выделенный под индекс
 *  - tbl_monitoring          : включен ли мониторинг на таблице, для которой создан индекс
 *  - idx_monitoring          : включен ли мониторинг индекса через ALTER INDEX MONITORING USAGE
 *  - index_used              : используется ли индекс, после включения на нём мониторинга
 *  - start_index_monitoring  : Дата и время включения мониторинга индекса 
 *  - last_index_used         : дата и время последнего использования индекса (заполнено, если
 *                              в v$index_usage_info поле index_stats_enabled равно 1 (oracle 12.2+ ))
 *  - last_analyzed           : дата и время последнего сбора статистики
 *  - last_data_modification  : дата последней модификации данным (DML). Заполняется при ключенном 
 *                              на таблице мониторинге. 
 *                              Данное поле, также как и inserts, updates, deletes заполняются с 
 *                              момента последнего сбора статистики, то есть после last_analyzed
 *  - inserts                 : количество вставленных строк (insert) в таблицу
 *  - updates                 : количество измененных строк (update) в таблице
 *  - deletes                 : количество удаленных строк (delete) из таблицы
 *  - row_modified_per_minute : среднее количество модифицированных строк за период между last_analyzed 
 *                              и last_data_modification
 * =================================================================================================
 */
with source as (
    select 'A4M' index_owner, interval'12'month depth from dual
),
index_list_out_of_plan(index_owner, index_name) as (
    -- индекс не был найден в dba_hist_sql_plan и в v$sql_plan
    select 
        owner, object_name 
    from (
        select do.owner, do.object_name, sp.sql_id from dba_objects do 
            left join dba_hist_sql_plan sp on sp.object# = do.object_id where do.object_type = 'INDEX' and do.owner = (select index_owner from source)
        union all
        select do.owner, do.object_name, sp.sql_id from dba_objects do 
            left join gv$sql_plan sp on sp.object# = do.object_id where do.object_type = 'INDEX' and do.owner = (select index_owner from source)
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
--    where dt.table_name like 'UBRR_%'
--    where dt.table_name not like 'TTX$%' and dt.table_name not like 'TDS$%' --and dt.table_name not like 'HCF_%'
    group by di.owner, di.index_name, di.uniqueness, 
        dt.owner, dt.table_name, dt.last_analyzed, dt.monitoring
)

select
    -- common --
    ilts.index_owner, 
    ilts.index_name, 
    ilts.table_name, 
    ilts.uniqueness, 
    uc.constraint_type, 
    ilts.index_total_mb,
    -- monitoring --
    ilts.monitoring tbl_monitoring, 
    ou.monitoring idx_monitoring, 
    ou.used index_used, 
	to_date(ou.start_monitoring, 'mm/dd/yyyy hh24:mi:ss') start_index_monitoring,
    iu.last_used last_index_used, 
    -- dml stats -- 
    ilts.last_analyzed, 
    dm.timestamp last_data_modification, 
    dm.inserts, 
    dm.updates, 
    dm.deletes, 
    round((dm.inserts + dm.updates + dm.deletes) / ((dm.timestamp - ilts.last_analyzed) * 1440)) row_modified_per_minute
from index_list_tab_space ilts
    left join dba_index_usage iu on iu.owner = ilts.index_owner and iu.name = ilts.index_name
    left join user_object_usage ou on ou.index_name = ilts.index_name and ou.table_name = ilts.table_name
    left join dba_tab_modifications dm on dm.table_owner = ilts.table_owner and dm.table_name = ilts.table_name and dm.partition_name is null
    left join user_constraints uc on uc.index_owner = ilts.index_owner and uc.index_name = ilts.index_name
--where (ou.used is null and ou.monitoring = 'YES')
--    or (iu.last_used is null and exists (select 0 from v$index_usage_info where index_stats_enabled = 1))
--    or (greatest(ou.used, iu.last_used) <= sysdate - (select depth from source))
order by index_total_mb desc nulls last;
