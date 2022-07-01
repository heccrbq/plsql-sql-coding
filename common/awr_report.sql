/**
 * =============================================================================================
 * Запрос генерации AWR отчета в формате HTML на текущей БД с указанием snapshot'ов
 * =============================================================================================
 * @param   start_snap_id   Стартовый снепшот генерации отчета
 * @param   end_snap_id     Конечный снепшот генерации отчета
 * =============================================================================================
 * Описание полей:
 *  - file#  : имя сгенерированного AWR отчета
 *  - output : содержание AWR отчета
 */
with source as (
    select name, dbid, inst_id, 98566 start_snap_id, 98567 end_snap_id from gv$database
--    select snap_id, begin_interval_time,end_interval_time from dba_hist_snapshot order by snap_id desc
)
select
    'AWR_' || lower(name) || '_' || start_snap_id || '_' || end_snap_id || '.html' file#,
    dbms_xmlgen.convert(xmlagg(xmlelement(output, output || chr(10)) order by rownum).extract('//text()').getclobval(),1) output
from source,
    table(dbms_workload_repository.awr_report_html(dbid, inst_id, start_snap_id, end_snap_id))
group by name, dbid, inst_id, start_snap_id, end_snap_id;
