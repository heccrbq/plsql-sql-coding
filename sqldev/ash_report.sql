/**
 * =============================================================================================
 * Запрос генерации ASH отчета по указанному sql_id в HTML формате
 * =============================================================================================
 * @param   start_date (DATE)        Дата начала
 * @param   end_date   (DATE)        Дата окончания
 * @param   sid        (NUMBER)      SID сессии
 * @param   sql_id     (VARCHAR2)    SQL_ID конкретного запроса
 * =============================================================================================
 * Описание полей:
 *  - file#  : имя сгенерированного отчета
 *  - output : содержание отчета
 */
with source as (
    select null start_date, null end_date, null sid, '9xf8bc1w04q4g' sql_id from gv$database
)
select
    'ASH_' || lower(d.name) || '_' || d.inst_id || '_' || s.start_date || '_' || s.end_date || '_' || s.sid || '_' || s.sql_id || '.html' file#,
    dbms_xmlgen.convert(xmlagg(xmlelement(output, t.output || chr(10)) order by rownum).extract('//text()').getclobval(),1) output
from source s,
    gv$database d,
    table(dbms_workload_repository.ash_report_html(l_dbid     => d.dbid, 
                                                   l_inst_num => d.inst_id, 
                                                   l_btime    => s.start_date, 
                                                   l_etime    => s.end_date,
                                                   l_sid      => s.sid,
                                                   l_sql_id   => s.sql_id)) t
group by d.name, d.dbid, d.inst_id, s.start_date, s.end_date, s.sid, s.sql_id;
