1. Запрос с получением всех статистик используемых объектов в запросе

say(dbms_utility.format_call_stack);
say(dbms_utility.format_error_stack);
say(dbms_utility.format_error_backtrace);


hcf_log.setlogoption(pmodule => c_module, ptarget => c_target, pdescription => ctaskname);





create or replace PACKAGE hcf_part_tools IS

  /**
  * =============================================================================================
  * Процедура добавления новых партиций к таблице на основе коллекции hcf_part_tools
  * =============================================================================================
  * @param   ptable_owner   Пользователь/владелец таблицы
  */
  FUNCTION <function_name>(ptable_owner IN VARCHAR2) RETURN hcf_partition_list;

END hcf_part_tools;
/
create or replace PACKAGE BODY hcf_part_tools IS

  /**
  * =============================================================================================
  * Функция получения текущей версии пакета
  * =============================================================================================
  */
  FUNCTION packageversion RETURN VARCHAR2 IS
  BEGIN
    -- 19.11.01 on 15.11.2019 by DVBykov - JIRATW-51659: Создание пакета нарезки партиций
    RETURN '19.11.01';
  END packageversion;
  
  /**
  * =============================================================================================
  * Процедура добавления новых партиций к таблице на основе коллекции hcf_part_tools
  * =============================================================================================
  * @param   ptable_owner   Пользователь/владелец таблицы
  */
  FUNCTION <function_name>(ptable_owner IN VARCHAR2) RETURN hcf_partition_list
  is
  ...
  
END hcf_part_tools;
/





--- sga_buffers.sql
SELECT t.name AS tablespace_name,
       o.object_name,
       SUM(DECODE(bh.status, 'free', 1, 0)) AS free,
       SUM(DECODE(bh.status, 'xcur', 1, 0)) AS xcur,
       SUM(DECODE(bh.status, 'scur', 1, 0)) AS scur,
       SUM(DECODE(bh.status, 'cr', 1, 0)) AS cr,
       SUM(DECODE(bh.status, 'read', 1, 0)) AS read,
       SUM(DECODE(bh.status, 'mrec', 1, 0)) AS mrec,
       SUM(DECODE(bh.status, 'irec', 1, 0)) AS irec
FROM   v$bh bh
       JOIN dba_objects o ON o.object_id = bh.objd
       JOIN v$tablespace t ON t.ts# = bh.ts#
GROUP BY t.name, o.object_name;


		  

select utl_lms.format_message(
           '| %s | %s | %s | %s | %s | %s | %s | %s | %s'
           , lpad(r.sid      ||' ', 5,' ')
           , lpad(r.delta    ||' ',15,' ')
           , rpad(r.username ||' ',25,' ')
           , rpad(r.program  ||' ',22,' ')
           , lpad(r.sql_id   ||' ',15,' ')
           , rpad(r.osuser   ||' ',15,' ')
           , lpad(r.event    ||' ',15,' ')
           , lpad(r.status   ||' ',15,' ')
         )) from dual;
		 

-- LONG IN SELECT
select 
dbms_xmlgen.convert(xmlquery( 'for $i in //*
              return $i/text()' passing dbms_xmlgen.getxmltype(
                'select column_expression from dba_ind_expressions where index_owner = '''
                || ic.index_owner
                || ''' and index_name = '''
                || ic.index_name
                || ''' and column_position = '''
                || ic.column_position
                || ''''
              ) returning content 
          ).getstringval(),1) x,
ic.* from dba_ind_columns ic
where ic.index_name = 'TENTRY_IDX01';


-- CLUSTERING_FACTOR & NUM_ROWS 
select dt.owner, dt.table_name, to_char(dt.num_rows, 'fm999G99G999G999') num_rows, 
                 di.index_name, to_char(di.clustering_factor, 'fm999G99G999G999') clustering_factor 
from dba_tables dt , dba_indexes di where dt.table_name = di.table_name and di.index_name = 'IDX_TCARDLOG';



set serveroutput on
declare
    procedure p1 is 
        procedure p2 is 
            procedure p3 is
                procedure p4 is 
                begin
                dbms_output.put_line(utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram (dynamic_depth => 1))); 
                end;
            begin
                p4;
            end;
        begin
            p3;
        end;
    begin
        p2;
    end;
begin 
    p1;
end;



-- ADD LINE IF NOT EXISTS
explain plan for
   insert into hcf_tsettingsvalue (id, value_num) select :vsetid, :vexchid from dual where not exists (select null from hcf_tsettingsvalue tg where tg.id = :vsetid);
   
   explain plan for
   MERGE INTO hcf_tsettingsvalue tg
 	 		    USING DUAL
 	 		    ON (tg.id = :vsetid)
 	 		    WHEN NOT MATCHED THEN
 	 		      INSERT (id, value_num) VALUES (:vsetid, :vexchid);
				  




-- Поиск запросов, в которых использовался SPD (SQL Plan Directives)
select first_load_time,
    inst_id,
    sql_id,
    count(1) spd_cursors,
    sum(spd_used) spd_used
from 
    (select inst_id,
        sql_id,
        extractvalue(xmlval, '/*/spd/cu') as spd_used
    from
        (select p.inst_id,
            p.sql_id,
            xmltype(p.other_xml) xmlval,
            s.is_reoptimizable      -- 'Y' означает, что выполнялась реоптимизация создания нового плана на основе статистики предыдущего выполнения 
                                    -- Automatic Reoptmization и запросы вида /*DS_SVC*/ /*+dynamic_sampling(0)*/
        from gv$sql_plan p,
            gv$sql s
        where p.inst_id = s.inst_id
            and p.child_address = s.child_address
            and p.sql_id = s.sql_id
            and p.other_xml is not null))
    join gv$sqlarea a using(inst_id, sql_id)
where spd_used > 0      --  используется SPD (SQL Plan Directives)
group by first_load_time,
    inst_id,
    sql_id
order by first_load_time desc


Objects referenced in the statement
  TEVNCMSSCHSETUP[TS] 5331842, type = 1
  TCLIENTCNSOBJ[TC] 4789577, type = 1
Objects in the hash table
  Hash table Object 4789577, type = 1, ownerid = 963275499174642696:
    Dynamic Sampling Directives at location 1:
       dirid = 6210196072749270602, state = 1, flags = 1, loc = 1, forDS = NO, forCG = YES {ECJ(4789577)[1, 4]}
  Hash table Object 5331842, type = 1, ownerid = 6574896176565205793:
    No Dynamic Sampling Directives for the object
	
	
select d.* from dba_sql_plan_directives d where directive_id = 6210196072749270602;

<spd_note>
    <internal_state>NEW</internal_state>
    <redundant>NO</redundant>
    <spd_text>{ECJ(A4M.TCLIENTCNSOBJ)[BRANCH, CNSPROFILE]}</spd_text>
</spd_note>


select * from dba_sql_plan_dir_objects where directive_id = 6210196072749270602;

<obj_note>
    <equality_predicates_only>YES</equality_predicates_only>
    <simple_column_predicates_only>YES</simple_column_predicates_only>
    <index_access_by_join_predicates>YES</index_access_by_join_predicates>
    <filter_on_joining_object>NO</filter_on_joining_object>
</obj_note>




select * from V$PX_PROCESS_TRACE;
select * from V$DIAG_SQL_TRACE_RECORDS



alter session set tracefile_identifier='10046_test1'; 
alter session set timed_statistics = true;
alter session set statistics_level=all;
alter session set max_dump_file_size = unlimited;



NLJ_PREFETCH
NO_NLJ_PREFETCH
NLJ_BATCHING
NO_NLJ_BATCHING

create table dropme2 pctfree 0 as
with dc as (select --+materialize 
rowid rwd from a4m.tdocument doc where doc.Branch = 1
                              AND doc.opdate >= date'2019-04-01'
--                              AND doc.newdocno IS NULL
                              )
                              
                              select /*alalala*/ /*+parallel(8) use_nl(doc dc)*/ * from a4m.tdocument doc, dc where doc.rowid = dc.rwd;
							  
							  
							  
							  
							  
-- Причина большого количества одинаковых запросов в select * from v$sql_shared_cursor where sql_id = '1xgyg1chpthqb';
-- Определяем MISMATCH
select extractvalue(t1.column_value, '//ROW/SQL_ID') as sql_id,
       extractvalue(t1.column_value, '//ROW/CHILD_NUMBER') as child_number,
       t2.column_value.getrootelement() as property,
       extractvalue(t2.column_value, '/*') as value
  from table(xmlsequence(extract(xmltype(cursor(select * from v$sql_shared_cursor where sql_id = '1xgyg1chpthqb')), '//ROW'))) t1,
       table(xmlsequence(extract(t1.column_value, '/*/*'))) t2
 where t2.column_value.getrootelement() like '%MISMATCH' and extractvalue(t2.column_value, '/*') <> 'N';
 
 
 select column_value
     from xmltable('for $i in ora:view("SYS","V_$SQL_SHARED_CURSOR")
    where $i/ROW/SQL_ID eq $s
    return element r{$i/ROW/SQL_ID, $i/ROW/*}' passing '1xgyg1chpthqb' as "s");


select t1.column_value.getstringval() from table(xmlsequence(extract(xmltype(cursor(select * from v$sql_shared_cursor where sql_id = '1xgyg1chpthqb')), '//ROW'))) t1,
table(xmlsequence(extract(t1.column_value, '/*/*'))) t2;




-- скрытые параметры и параметры в init файлах
-- Этот скрипт запускается под пользователем SYS, потому что только пользователь SYS имеет доступ к внутренним таблицам X$.
select
   a.ksppinm  parameter,
   a.ksppdesc description,
   b.ksppstvl session_value,
   c.ksppstvl instance_value
from x$ksppi a,
   x$ksppcv b,
   x$ksppsv c
where a.indx = b.indx
   and a.indx = c.indx
   and a.ksppinm = '_hash_multiblock_io_count';






-- генерация партиций на несколько дней вперед от sysdate
select
    'alter table CNS_ARCHIVE add ' || chr(10) ||
    listagg(
     '    partition CNS_' || to_char(sysdate+level-1,'yymmdd') || 
     ' values less than (TO_DATE(''' || to_char(trunc(sysdate+level), 'yyyy-mm-dd hh24:mi:ss') || ''', ''YYYY-MM-DD HH24:MI:SS'', ''NLS_CALENDAR=GREGORIAN''))', ',' || chr(10) ) within group(order by level) || ';'
     from dual connect by  level <= 7/*нарезать вперед на n дней*/;






show parameter PGA_AGGREGATE_TARGET



select
    sp.id,
    lpad(' ', 2*sp.depth) || sp.operation || nvl2(sp.optimizer, ' (' || sp.optimizer || ')', null) operation, 
    sp.options, sp.object_owner, sp.object_name, sp.object_type,
    sp.access_predicates, sp.filter_predicates, -- / ash.ash_delta_read percent_load_bytes,
    -- session
    s.event, s.p1text, s.p1, s.p2text, s.p2, s.p3text, s.p3,
    s.row_wait_obj#, s.row_wait_file#, s.row_wait_block#, s.row_wait_row#,
    -- longops & ash
    sl.opname, sl.target, sl.message, sl.sofar, sl.totalwork, sl.units, round(sofar/totalwork * 100,4) percentage_complete, sl.time_remaining, sl.elapsed_seconds, ash.ash_delta_time,
    -- workarea
    swa.active_time, round(sw.estimated_optimal_size/1024/1024, 4) est_opt_size_mb, round(sw.estimated_onepass_size/1024/1024, 4) est_onepass_size_mb, 
                     round(swa.expected_size/1024/1024, 4) exp_size_mb, round(swa.actual_mem_used/1024/1024, 4) act_size_mb, round(swa.tempseg_size/1024/1024, 4) temp_size_mb, su.temp_usage,
    -- sqlarea
    sa.executions, sa.px_servers_executions, sa.rows_processed, sa.elapsed_time, sa.plsql_exec_time, sa.cpu_time, sa.application_wait_time, sa.concurrency_wait_time, sa.user_io_wait_time,
    sa.program_id, sa.program_line#
from v$sql_plan sp,
    v$session s,
    v$sqlarea sa,
    v$session_longops sl,
    v$sql_workarea sw,
    v$sql_workarea_active swa,
    (select ash.sql_id, ash.sql_child_number, ash.sql_plan_line_id,
        round(sum(delta_time)/1e6, 4) ash_delta_time, sum(delta_read_io_bytes) ash_delta_read 
     from v$active_session_history ash
     group by ash.sql_id, ash.sql_child_number, ash.sql_plan_line_id) ash,
     lateral
        (select round(sum(u.blocks * to_number(p.value) /1024 / 1024), 4) temp_usage from v$sort_usage u, v$parameter p where s.saddr = u.session_addr and p.name = 'db_block_size') su
where sp.address = s.sql_address
    and sp.sql_id = s.sql_id
    and sp.address =sa.address
    and sp.sql_id = sa.sql_id
    and sp.address = sl.sql_address (+)
    and sp.sql_id = sl.sql_id (+)
    and sp.id = sl.sql_plan_line_id (+)
    and s.sid = sl.sid (+)
    and s.serial# = sl.serial# (+)
    and sp.address = sw.address (+)
    and sp.sql_id = sw.sql_id (+)
    and sw.workarea_address = swa.workarea_address (+)
    and sp.id = swa.operation_id (+)
    and sp.sql_id = ash.sql_id (+) and s.sql_child_number = ash.sql_child_number (+) and sp.id = ash.sql_plan_line_id (+)
    and s.sid = 521
order by sp.id;




-- использование undo по шагам плана
select event, sql_plan_line_id, count(1) 
from dba_hist_active_sess_history where sql_id = '3x647rx85y5a7' and snap_id between 85477 and 85496
    and current_file# in (select relative_fno from dba_data_files where tablespace_name in (select tablespace_name from dba_tablespaces where contents = 'UNDO'))
group by event, sql_plan_line_id
order by 1,2 , 3;


-- параллельный запрос
select lpad(' ', 4*(level -1)) || px.sid sid, px.serial#
    ,px.*  
    ,s.event, s.sql_id, s.status, s.sql_exec_id, s.taddr, s.p1, s.p1raw, s.p1text
    ,p.*
    ,sl.*
    ,rs.*
from v$px_session px 
    left join v$session s on px.sid = s.sid and px.serial# = s.serial#
    left join v$px_process p on p.sid = px.sid and p.serial# = px.serial#
    left join v$pq_slave sl on sl.slave_name = p.server_name
    left join v$rsrc_session_info rs on rs.sid = px.sid
start with px.qcserial# is null --and px.qcsid = 59
connect by prior px.sid = px.qcsid and px.qcserial# is not null;




select
    -- mview
    mv.mview_name, mv.refresh_mode, mv.build_mode, mv.fast_refreshable, mv.last_refresh_type, mv.last_refresh_date, mv.staleness, mv.compile_state,
    -- mview log
    mvl.master, mvl.log_table, decode(mvl.rowids, 'NO', 'WITH ROWID', mvl.primary_key, 'YES', 'WITH PRIMARY KEY', '?') with_option, mvl.include_new_values,
    -- base_table_mviews
    btm.mview_last_refresh_time, btm.mview_id,
    -- stats
    mvs.refresh_id, mvs.refresh_method, mvs.elapsed_time, mvs.initial_num_rows, mvs.final_num_rows, 
    mvc.num_rows_ins, mvc.num_rows_upd, mvc.num_rows_del, mvc.num_rows_dl_ins, mvc.num_rows
    --, query
from dba_mviews mv
    left join dba_mview_refresh_times mrt on mrt.name = mv.mview_name and mrt.master = 'TCONTRACT'
    left join dba_mview_logs mvl on mvl.master = mrt.master
    left join dba_base_table_mviews btm on btm.master = mvl.master
    outer apply (select * from dba_mvref_stats mvs where mvs.mv_name = mv.mview_name order by refresh_id fetch first 1 rows only) mvs
    outer apply (select * from dba_mvref_change_stats  mvc where mvc.mv_name = mv.mview_name and mvc.tbl_name = mrt.master and mvc.refresh_id = mvs.refresh_id) mvc
where mv.mview_name = 'MV_ACTION_CLIENTS';


with t as (select column_value table_name from table(sys.odcivarchar2list('TENTRY',
'TDOCUMENT',
'TPOSCHEQUE',
'TPAYMENTEXTINFO',
'TATMEXT',
'TPAYMENTEXT',
'TEXCOMMON',
'TOPERATIONRATESEXT',
'TEVENTPAYMENTEXT',
'TLOYALTYEXT',
'TLOYALTYEXTBON',
'TVOICESLIP',
'TCHEQUEEXT',
'TPRIZEEXT')))

select decode(typ, 'INDEX', lpad(' ', 4)) || obj obj, --tab,
    round(sum(bytes)/1024/1024/1024,3) gb
from 
    (select table_name obj, table_name tab, 'TABLE' typ from user_tables natural join t
    union all
    select index_name, table_name, 'INDEX' from user_indexes natural join t)
    left join user_segments on segment_name = obj
group by grouping sets ((obj, tab, typ), (tab), ())
order by tab, obj  desc nulls last;











select 
    sql_plan_line_id,
    session_state, event, 
    (select object_name from all_objects where object_id = current_obj#) obj,
    wait_class, count(1) wait_count, 
    round(sum(time_waited)/1e3, 2) time_waited,
    round((ratio_to_report(count(1)) over ())*100, 2) as percent
from v$active_session_history
where sql_id = 'd8tav4gvx2898'/*:sql_id*/
--    and sql_exec_id = 16777216
group by session_state, event, wait_class, sql_plan_line_id, current_obj#
order by 1, wait_count desc;








col tbl for a25
with t as (
    select 
        a.column_value || b.column_value tbl 
    from table(sys.odcivarchar2list(null, 'ARC')) b,
        table(sys.odcivarchar2list(
            'TENTRY',
            'TDOCUMENT',
            'TPOSCHEQUE',
            'TPAYMENTEXTINFO',
            'TATMEXT',
            'TPAYMENTEXT',
            'TEXCOMMON',
            'TOPERATIONRATESEXT',
            'TEVENTPAYMENTEXT',
            'TLOYALTYEXT',
            'TLOYALTYEXTBON',
            'TVOICESLIP',
            'TCHEQUEEXT',
            'TPRIZEEXT')) a)

select tbl, dbms_xmlgen.getxmltype('select /*+parallel(8)*/ count(1) from ' || tbl).extract('//text()').getnumberval() cnt  from t order by 1;







select 
    sp.id, decode(skip, 1,'SKIP', ' ') skip,
    lpad(' ', 4*sp.depth) || sp.operation || nvl2(sp.optimizer, '  Optimizer=' || sp.optimizer, null) ||
        nvl2(sp.options, ' (' || sp.options || ')', null) || 
        nvl2(sp.object_name, ' OF ''' || nvl2(sp.object_owner, sp.object_owner || '.', null) || sp.object_name || '''', null) ||
        decode(sp.object_type, 'INDEX (UNIQUE)', ' (UNIQUE)') ||
        '  (Cost=' || sp.cost || ' Card=' || sp.cardinality || ' Bytes=' || sp.bytes || ')' sqlplan
from v$sql_plan sp
left join (
select sp.sql_id, xt.* from v$sql_plan sp,
    xmltable('/other_xml/display_map/row' passing xmltype(sp.other_xml)
        columns id number path '@op',
--                parent_id number path '@par',
--                depth number path '@dep',
                skip number path '@skp') xt
    where sp.other_xml is not null) t on t.sql_id = sp.sql_id and t.id = sp.id
where sp.sql_id = 'ff8wx3qsmwr3r' order by sp.child_number, sp.id;



-- объекты, используемые в запросе
select * from (
select table_name from user_indexes where index_name in (
select object_name from dba_objects where (object_name, object_type) in (
    select object_name, regexp_replace(object_type, ' .+') from v$sql_plan where sql_id = '3x647rx85y5a7' and object_type is not null) and object_type = 'INDEX')
union
select object_name from dba_objects where (object_name, object_type) in (
    select object_name, regexp_replace(object_type, ' .+') from v$sql_plan where sql_id = '3x647rx85y5a7' and object_type is not null) and object_type = 'TABLE')x left join user_tables t
    on x.table_name = t.table_name
    order by 1;


select 
    -- dba_objects
    o.owner, o.object_name, o.object_id, o.data_object_id, o.last_ddl_time,
    -- dba_segments
    s.header_file, s.header_block, s.bytes, s.blocks, s.extents, s.initial_extent, s.min_extents, s.max_extents, 
    -- dba_tables
    t.pct_free, t.pct_used, t.pct_increase, t.ini_trans, t.max_trans, t.initial_extent, t.min_extents, t.max_extents, t.num_rows, t.avg_row_len, t.blocks, t.empty_blocks, 
    --
    round((t.num_rows * avg_row_len) /  ((select to_number(value) from v$parameter where name = 'db_block_size') * (1 - t.pct_free / 100))) real_blocks
from dba_segments s 
    join dba_tables t on t.table_name = s.segment_name and t.owner = s.owner
    join dba_objects o on o.object_name = s.segment_name and o.owner = s.owner
where s.segment_name = 'DROPME5';
	
	
	





SELECT * FROM TABLE(dbms_xplan.display_cursor(sql_id => ‘8t6w2p8snazn9’, cursor_child_no => 0, 
	FORMAT => ‘TYPICAL -ROWS -BYTES +COST +PARALLEL +PARTITION +IOSTATS +MEMSTATS +ALIAS +PEEKED_BINDS +OUTLINE +PREDICATE -PROJECTION +REMOTE +NOTE’));

I wish there was an option like “-SQLTEXT” or “-QUERY” so that I start seeing the results starting from the line that says “Plan hash value: ……”






col parameter for a30
col database_value for a20
col instance_value for a20
col session_value for a20
select 
    coalesce(d.parameter, i.parameter, s.parameter) parameter,
    d.value database_value,
    i.value instance_value,
    s.value session_value
from nls_database_parameters d
    full join nls_instance_parameters i on d.parameter = i.parameter
    full join nls_session_parameters s on s.parameter = coalesce(d.parameter, i.parameter)
where coalesce(d.parameter, i.parameter, s.parameter) = 'NLS_LENGTH_SEMANTICS';









set serveroutput on
set timing on
declare
  PROCEDURE logtimerresults(ptext VARCHAR) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    timeresultslist timer.typeresults;
    i               VARCHAR(100);
  BEGIN
    timeresultslist := timer.getresultlist();
    i               := timeresultslist.first;
    WHILE i IS NOT NULL LOOP
      s.say(ptext || ' - ' || RPAD(i, 20) || ' : time = ' || ROUND(timeresultslist(i).score / 100, 2) || 'sec.; count = ' || timeresultslist(i)
            .count || '; warn = ' || timeresultslist(i).warn);
      EXECUTE IMMEDIATE 'insert into tTimer(Ident,Id,Score,Count,Warn)
        values(:1,:2,:3,:4,:5)'
        USING ptext, i, ROUND(timeresultslist(i).score / 100, 2), timeresultslist(i).count, timeresultslist(i).warn;
      i := timeresultslist.next(i);
    END LOOP;
    COMMIT; --< AUTONOMOUS!!!
  END logtimerresults;
  procedure p is
  begin
    for i in (select * from dual connect by level <= 5)
    loop
        timer.start_('step#2');
        dbms_lock.sleep(1);
        timer.stop_('step#2');
    end loop;
  end;
begin
    timer.clear();
    timer.start_('step#1');
    dbms_lock.sleep(3);
    p;
    timer.stop_('step#1');
    logtimerresults('dvbykov#2');
end;
/

select * from ttimer where ident = 'dvbykov' order by created desc, id;











-- горячий объект
with check_sql as (
    select /*+ materialize */
        sql_id
    from gv$sql
    where hash_value in (select from_hash from gv$object_dependency where to_name = 'TENTRY')
)

select 
    to_char(sn.end_interval_time, 'yyyy/mm/dd hh24:mi') snap_time,
    sum(s.executions_delta) exec_cnt,
    round(sum(s.executions_delta / (cast(sn.end_interval_time as date) - cast(sn.begin_interval_time as date))/24/60)) exec_cnt_per_minute
from dba_hist_sqlstat s,
    dba_hist_snapshot sn
where s.sql_id in (select /*+ no_unnest */ sql_id from check_sql)
    and s.snap_id = sn.snap_id
    and s.dbid = sn.dbid
    and s.instance_number = sn.instance_number
    and sn.end_interval_time between sysdate-1 and sysdate
group by to_char(sn.end_interval_time, 'yyyy/mm/dd hh24:mi')
order by 1 desc;
