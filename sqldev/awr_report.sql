/**
 * =============================================================================================
 * Запрос генерации AWR отчета в формате HTML на текущей БД с указанием snapshot'ов
 * =============================================================================================
 * @param   start_snap_id (NUMBER)   Стартовый снепшот генерации отчета
 * @param   end_snap_id   (NUMBER)   Конечный снепшот генерации отчета
 * =============================================================================================
 * Описание полей:
 *  - file#  : имя сгенерированного отчета
 *  - output : содержание отчета
 */
with source as (
    select name, dbid, inst_id, 98566 start_snap_id, 98567 end_snap_id from gv$database
--    select snap_id, begin_interval_time,end_interval_time from dba_hist_snapshot order by snap_id desc
)
select
    'AWR_' || lower(s.name) || '_' || s.start_snap_id || '_' || s.end_snap_id || '.html' file#,
    dbms_xmlgen.convert(xmlagg(xmlelement(output, t.output || chr(10)) order by rownum).extract('//text()').getclobval(),1) output
from source s,
    table(dbms_workload_repository.awr_report_html(l_dbid     => s.dbid, 
                                                   l_inst_num => s.inst_id, 
                                                   l_bid      => s.start_snap_id, 
                                                   l_eid      => s.end_snap_id)) t
group by s.name, s.dbid, s.inst_id, s.start_snap_id, s.end_snap_id;



/**
 * =============================================================================================
 * Запрос генерации AWR отчета в формате HTML на текущей БД с указанием snapshot'ов
 * =============================================================================================
 * @param   start_snap_id (DATE)   Стартовое время генерации отчета
 * @param   end_snap_id   (DATE)   Конечное время генерации отчета
 * =============================================================================================
 * Описание полей:
 *  - file#  : имя сгенерированного отчета
 *  - output : содержание отчета
 */
with source as (
    select timestamp'2022-07-04 04:47:00' start_time, timestamp'2022-07-04 05:37:00' end_time from dual
),
awr as (
    select 
        d.name, d.dbid, d.inst_id, lt.start_snap_id, lt.end_snap_id
    from gv$database d,
    lateral(
        select min(snap_id) start_snap_id, max(snap_id) end_snap_id
        from dba_hist_snapshot sn, source s
        where sn.dbid = d.dbid and sn.instance_number = d.inst_id 
            and (s.start_time between sn.begin_interval_time and sn.end_interval_time 
                or s.end_time between sn.begin_interval_time and sn.end_interval_time)) lt
)
--select * From awr;
select
    'AWR_' || lower(awr.name) || '_' || awr.inst_id || '_' || awr.start_snap_id || '_' || awr.end_snap_id || '.html' file#,
    dbms_xmlgen.convert(xmlagg(xmlelement(output, t.output || chr(10)) order by rownum).extract('//text()').getclobval(),1) output
from awr,
    table(dbms_workload_repository.awr_report_html(l_dbid     => awr.dbid, 
                                                   l_inst_num => awr.inst_id, 
                                                   l_bid      => awr.start_snap_id, 
                                                   l_eid      => awr.end_snap_id)) t
group by awr.name, awr.dbid, awr.inst_id, awr.start_snap_id, awr.end_snap_id;
