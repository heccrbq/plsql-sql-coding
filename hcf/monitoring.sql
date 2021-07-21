/**
 * =============================================================================================
 * ASH: Затраченное время (db_time / cpu_time) и количество io реквестов на чтение и запись
 * =============================================================================================
 * @param   sql_id   				Уникальный идентификатор запроса
 * =============================================================================================
 * Описание полей:
 *	- sql_exec_id : 
 *  - sql_plan_hash_value : 
 *  - query_duration : дата и время начала снепшота, в котором был замечен запрос
 *  - db_time_sec : длительность снепшота
 *  - cpu_time_sec : как часто выполнялся запрос, в течение <minutes>
 *  - io_requests : время выполнения (elapsed time) запроса
 *  - io_mb : 
 * =============================================================================================
 */
select
    sql_exec_id,
    sql_plan_hash_value,
    max(sample_time)- min(sample_time) AS query_duration,
    round(sum(tm_delta_db_time)/1e6)   AS db_time_sec,
    round(sum(tm_delta_cpu_time)/1e6)  AS cpu_time_sec,
    sum(delta_read_io_requests + delta_write_io_requests) AS io_requests,
    round(sum(delta_read_io_bytes + delta_write_io_bytes)/1024/1024) AS io_mb
from v$active_session_history ash
where sql_id = '4tnags1a8kvb8' /*:sql_id*/
--    and sql_exec_id between 17017534 and 17017547
group by sql_exec_id, sql_plan_hash_value
order by sql_exec_id;
