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
    'AWR_' || lower(s.name) || '_' || s.start_snap_id || '_' || s.end_snap_id || '.html' file#,
    dbms_xmlgen.convert(xmlagg(xmlelement(output, t.output || chr(10)) order by rownum).extract('//text()').getclobval(),1) output
from source s,
    table(dbms_workload_repository.awr_report_html(l_dbid =>     s.dbid, 
                                                   l_inst_num => s.inst_id, 
                                                   l_bid =>      s.start_snap_id, 
                                                   l_eid =>      s.end_snap_id)) t
group by s.name, s.dbid, s.inst_id, s.start_snap_id, s.end_snap_id;
