/**
 * =============================================================================================
 * Запрос генерации отчета использования полей указанной таблицы
 * =============================================================================================
 * @param   owner        Владелец таблицы
 * @param   table_name   Наименование таблицы
 * =============================================================================================
 * Описание полей:
 *  - file#  : имя сгенерированного AWR отчета
 *  - output : содержание AWR отчета
 */
with source as (
    select 'A4M' owner, 'TDOCUMENT' table_name from dual
)
select 
    'COLUSAGE_' || lower(owner) || '_' || lower(table_name) || '.txt' file#,
    dbms_stats.report_col_usage(owner, table_name) output 
from source;