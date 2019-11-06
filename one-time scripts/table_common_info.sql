/**
 * =============================================================================================
 * Общая инфа по таблице: количество строк, занимаемое место, секционирование и тд.
 * =============================================================================================
 * @param   p_table_owner   Владелец таблицы
 * @param   p_table_table   Наименование таблицы
 * =============================================================================================
 * Описание полей:
 *   - Владелец
 *   - наименование таблицы
 *   - наименование тейблспейса
 *   - Количество строк по статистике
 *   - Занимаемое место сегментом
 *   - Ялвяется ли таблица GTT
 *   - Партицирована ли таблица
 *   - Тип партицирования
 *   - Поля партицирования
 *   - Количество партиций
 *   - Наименование PK констрейнта + состав полей, входящих в него
 */
select dt.owner, 
  dt.table_name,
  coalesce(dt.tablespace_name, dpt.def_tablespace_name) tablespace_name,
  to_char(dt.num_rows,'fm999G999G999G999') num_rows_by_stats,
  case when sum(ds.bytes) >= power(2,30) then to_char(round(sum(ds.bytes) / 1024 / 1024 / 1024, 5)) || ' Gb' else to_char(round(sum(ds.bytes) / 1024 / 1024, 5)) || ' Mb' end local_storage,
  dt.temporary,
  dt.partitioned,
  dpt.partitioning_type,
  (select listagg(dpkc.column_name, ', ')within group(order by dpkc.column_position) from dba_part_key_columns dpkc where dpkc.owner = dt.owner and dpkc.name = dt.table_name) part_key_columns,
  dpt.partition_count,
  (select dc.constraint_name || '(' || listagg(dcc.column_name, ', ')within group(order by dcc.position) || ') ===> ' || dc.status
    from dba_constraints dc, dba_cons_columns dcc where dc.table_name = dt.table_name and dc.owner = dt.owner and dcc.owner = dc.owner and dcc.constraint_name = dc.constraint_name and dc.constraint_type = 'P'
    group by dc.constraint_name, dc.status) primary_key_constraint
from dba_tables dt
  left join dba_part_tables dpt on dpt.owner = dt.owner and dpt.table_name = dt.table_name
  left join dba_indexes di on di.table_owner = dt.owner and di.table_name = dt.table_name
  left join dba_segments ds on ds.owner = dt.owner and ds.segment_name = dt.table_name
where dt.owner = 'OWNER_DWH' /*:p_table_owner*/
  and dt.table_name = 'FT_CREDIT_BUREAU_DATA_TT' /*:p_table_table*/
group by dt.owner,
  dt.table_name,
  dt.temporary,
  dt.partitioned,
  dpt.partitioning_type,
  dpt.partition_count,
  dt.num_rows;
