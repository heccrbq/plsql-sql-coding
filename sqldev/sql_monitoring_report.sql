/**
 * =============================================================================================
 * Запрос генерации Real-Time отчета по указанному sql_id
 * =============================================================================================
 * @param   sql_id (VARCHAR2)   SQL_ID запроса
 * =============================================================================================
 * Описание полей:
 *  - file#  : имя сгенерированного отчета
 *  - output : содержание отчета
 */
with source as (
    select '6hjs0624rwqyy' sql_id from dual
)
select 
    'SQLMONITOR_' || sql_id || '.html' file#,
    dbms_sqltune.report_sql_monitor(sql_id =>       sql_id, 
                                    report_level => 'all', 
--                                    sql_exec_id =>  100500,
                                    type =>         'html') output
from source;
