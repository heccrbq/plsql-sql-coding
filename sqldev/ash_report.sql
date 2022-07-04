/**
 * =============================================================================================
 * Запрос генерации ASH отчета по указанному sql_id в HTML формате
 * =============================================================================================
 * @param   start_date (DATE)        дата начала
 * @param   end_date   (DATE)        дата окончания
 * @param   sid        (NUMBER)      SID сессии
 * @param   sql_id     (VARCHAR2)    SQL_ID конкретного запроса
 * =============================================================================================
 * Описание полей:
 *  - file#  : имя сгенерированного отчета
 *  - output : содержание отчета
 */
with source as (
    select name, dbid, inst_id, null start_date, null end_date, null sid, '9xf8bc1w04q4g' sql_id from gv$database
)
select
    'ASH_' || lower(s.name) || '_' || s.start_date || '_' || s.end_date || '.html' file#,
    dbms_xmlgen.convert(xmlagg(xmlelement(output, t.output || chr(10)) order by rownum).extract('//text()').getclobval(),1) output
from source s,
    table(dbms_workload_repository.ash_report_html(l_dbid     => s.dbid, 
                                                   l_inst_num => s.inst_id, 
                                                   l_btime    => s.start_date, 
                                                   l_etime    => s.end_date,
                                                   l_sid      => s.sid,
                                                   l_sql_id   => s.sql_id)) t
group by s.name, s.dbid, s.inst_id, s.start_date, s.end_date, s.sid, s.sql_id;
