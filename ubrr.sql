-- query content
select sql_id, sql_text from dba_hist_sqltext where sql_id = '0j0jx4qr38tzx';


-- package content
with settings as (
    select 'A4M' package_owner, 'CONTRACTRB' package_name from dual
)
select 
    owner || '.' || name || '.sql' package_name,
    dbms_xmlgen.convert(
        xmlagg(xmlelement(x, case when type = 'PACKAGE BODY' and line = 1 then '/' || chr(10) end || text) order by type, line)
            .extract('//text()').getclobval(), 1) || chr(10) || '/' package_content
from dba_source 
where (owner, name) in (select upper(package_owner), upper(package_name) from settings)
    and type in ('PACKAGE', 'PACKAGE BODY')
group by owner, name;


-- constraint list
with settings as (
    select 'A4M' table_owner, 'TCONTRACTITEM' table_name from dual
)
select c.owner, c.table_name, c.constraint_type, c.constraint_name,
    (select 
		listagg(column_name, ',')within group(order by position) 
	from dba_cons_columns cc 
	where cc.owner = c.owner and cc.table_name = c.table_name and cc.constraint_name = c.constraint_name) column_list,
     c.status,
     c.index_name
from dba_constraints c where (c.owner, c.table_name) in (select table_owner, table_name from settings)
order by table_name, constraint_type desc, constraint_name;


-- parallel max servers
parallel_max_servers =
   parallel_threads_per_cpu * cpu_count * concurrent_parallel_users * 5
   
alter system set parallel_max_servers = 36 scope=both;


REPRESERVE10_NEW 1998 PrepareCasheJAV


-- owner  : [null | <value>] : for example, 'SYS'
-- fixed : [Y | N] : Y - количество полей, равно сумме количества из attrs, N - количество полей любое, главное, чтоы присутствовали attrs
-- attrs : список типов данных атрибутов, которые должны присутствовать в типе
with source as (
    -- найти тип, владелец которого <ЛЮБОЙ>, в типе 3 поля, 2 из которых имеют типа VARCHAR2, одно поле имеет тип NUMBER
    select null owner, 'Y' fixed, sys.ku$_objnumnamset(sys.ku$_objnumnam(name => 'VARCHAR2', obj_num => 2), 
                                                       sys.ku$_objnumnam(name => 'NUMBER',   obj_num => 1), 
                                                       sys.ku$_objnumnam(name => 'DATE',     obj_num => 0)) attrs from dual
)

select * from source;

select owner, type_name, null package_name, attr_name, attr_type_name, length, precision, scale, attr_no from all_type_attrs;
select owner, type_name, package_name, attr_name, attr_type_name, length, precision, scale, attr_no from all_plsql_type_attrs;

select *
from 
    all_type_attrs dta;
    
select * From all_plsql_type_attrs;
where (dta.owner = s.type_owner or s.type_owner is null);




-- list of the data types
select distinct attr_type_name from sys.dba_type_attrs dta where attr_type_owner is null order by 1;
/





-- hidden parameters
select 
    a.ksppinm parameter,
    a.ksppdesc description,
    b.ksppstvl session_value,
    c.ksppstvl instance_value
from x$ksppi a,
    x$ksppcv b,
    x$ksppsv c
where a.indx = b.indx
    and a.indx = c.indx
    and a.ksppinm like '/_%adaptive%' escape '/'
order by a.ksppinm;



with source as (
    select 1457 sid, 53213 serial#, to_date('21.06.2022 17:18:49', 'dd.mm.yyyy hh24:mi:ss') exec_date from v$session where sid = userenv('sid')),
sbq as (
    select /*+no_merge*/ 
--        sql_id, sql_exec_id, count(1) rowcount 
        sql_id, count(distinct sql_exec_id || to_char(sql_exec_start, 'yyyymmddhh24:mi:ss')) unq_run, count(1) rowcount,
        round(sum(tm_delta_db_time)/1e6, 2) db_time, round(sum(tm_delta_cpu_time)/1e6, 2) cpu_time
    from v$active_session_history ash
        join source s on s.sid = ash.session_id and s.serial# = ash.session_serial#
--    where sample_time >= s.exec_date
--    group by sql_id, sql_exec_id
    group by sql_id
    )

select sbq.*, 
    (select owner || '.' || object_name || ' (' || lower(object_type) || ')' from all_objects where object_id = s.program_id) object_name,
    s.program_line#,
    s.* 
from sbq, v$sql s 
where sbq.sql_id = s.sql_id(+)
order by rowcount desc;





select ss.sid, ss.statistic#, st.name, ss.value/1024/1024 mbytes
from v$sesstat ss, v$statname st
where ss.statistic# = st.statistic# 
    and sid = userenv('sid') 
    and st.name in ('session pga memory',
                    'session pga memory max',
                    'session uga memory',
                    'session uga memory max');





select
    event, 
    obj,
	(select object_name || ' (' || lower(object_type) || ')' From dba_objects where object_id = obj) obj_name,
    count(1) wait_cnt,
--	decode(event, 'db file sequential read', count(distinct block)) unq_block,
    round(sum(to_number(ela))/1e6,2) total_ela_sec,
    round(avg(to_number(ela))/1e3,2) average_ela_milisec,
    round(sum(to_number(ela)),2) total_ela_microsec,
    round(avg(to_number(ela)),2) average_ela_microsec
from (
    select 
        regexp_replace(payload, '.*nam=''([^'']+)''.*', '\1') event,
        rtrim(regexp_replace(payload, '.*ela= (\d+).*', '\1'), chr(10)) ela,
        rtrim(regexp_replace(payload, '.*obj#=(-?\d+).*', '\1'), chr(10)) obj,
--		rtrim(regexp_replace(payload, '.*block#=(\d+).*', '\1'), chr(10)) block,
        payload
    from v$diag_trace_file_contents 
    where trace_filename = 'rtwr_ora_32047510.trc'
    and payload like '%WAIT #4858098144:%')
group by event, obj
order by total_ela_microsec desc;




select
    nam, 
--    obj,
    count(1) nam_cnt,
    round(sum(to_number(ela))/1e6,2) total_ela_sec,
    round(avg(to_number(ela))/1e3,2) average_ela_milisec,
    round(sum(to_number(ela)),2) total_ela_microsec,
    round(avg(to_number(ela)),2) average_ela_microsec
from (
    select 
        regexp_replace(payload, '.*nam=''([^'']+)''.*', '\1') nam,
        rtrim(regexp_replace(payload, '.*ela= (\d+).*', '\1'), chr(10)) ela,
--        regexp_replace(payload, '.*obj#=(-?\d+).*', '\1') obj,
        payload
    from v$diag_trace_file_contents 
    where trace_filename = 'rtwr_ora_32047510.trc'
    and payload like '%WAIT #4858098144:%')
group by nam
order by total_ela_microsec desc;






select
    regexp_replace(payload, '.*nam=''([^'']+)''.*', '\1') nam,
    regexp_replace(payload, '.*ela= (\d+).*', '\1') ela,
    regexp_replace(payload, '.*obj#=(-?\d+).*', '\1') obj,
    payload
--    to_number(trim(substr(payload, instr(payload, 'ela=') + 5, instr(payload, ' ', instr(payload,'ela=' ))))) ela,
--    to_number(trim(substr(payload, instr(payload, 'obj#=') + 5, instr(payload, ' tim=') - instr(payload, 'obj#=') - 5))) obj#,
--    instr(payload, ' ', instr(payload,'ela=' )) - instr(payload, 'ela=')
from (select column_value payload from table(sys.odcivarchar2list(
        q'[WAIT #4858098144: nam='Disk file operations I/O' ela= 110 FileOperation=2 fileno=19 filetype=2 obj#=97027 tim=91832074836228]' ,
        q'[WAIT #4858098144: nam='db file sequential read' ela= 634 file#=19 block#=81297 blocks=1 obj#=97027 tim=91832074837815]',
        q'[WAIT #4858098144: nam='read by other session' ela= 1175 file#=300 block#=1913866 class#=1 obj#=-1 tim=91832129609666]',
        q'[WAIT #4858098144: nam='buffer busy waits' ela= 30 file#=456 block#=395214 class#=1 obj#=-1 tim=91832100758207]')));



select * from v$session_event where sid = userenv('sid');
select event, sql_plan_operation, count(1) from v$active_session_history where sql_id = '48wfhpqnd2af0' and session_id = userenv('sid') group by event, sql_plan_operation;






-- bind peeking
select * from v$sql_bind_capture where sql_id = '4ksn3hvrd9bwz';

-- SQL Monitor
select sql_id, xt.* 
from v$sql_monitor, 
    xmltable('binds/*' passing xmltype(binds_xml) columns name     varchar2(128)  path '@name',
                                                          position number         path '@pos',
                                                          datatype varchar2(15)   path '@dtystr',
                                                          value    varchar2(1000) path '.') xt
where sql_id = '4ksn3hvrd9bwz';








select sql_id,
    count(distinct sql_exec_id) sql_exec_id,
    count(nullif(in_connection_mgmt, 'N')) in_connection_mgmt,
    count(nullif(in_parse, 'N')) in_parse,
    count(nullif(in_hard_parse, 'N')) in_hard_parse,
    count(nullif(in_sql_execution, 'N')) in_sql_execution,
    count(nullif(in_plsql_rpc, 'N')) in_plsql_rpc,
    count(nullif(in_plsql_compilation, 'N')) in_plsql_compilation,
    count(nullif(in_java_execution, 'N')) in_java_execution,
    count(nullif(in_bind, 'N')) in_bind,
    count(nullif(in_cursor_close, 'N')) in_cursor_close,
    count(nullif(in_sequence_load, 'N')) in_sequence_load
from v$active_session_history where session_id = 398 and session_serial# = 57981 group by sql_id;

select * from v$sql where sql_id = '9swq00fwrsk10';

select
    event, count(1)
from v$active_session_history where session_id = 398 and session_serial# = 57981 group by event;

select * from v$session_event where sid = 398;



select 
    t.owner, table_name, partitioned, num_rows, avg_row_len, 
    t.blocks,      -- blocks contains data (the other block is used by the system)
    empty_blocks,  -- blocks are totally empty (above the HWM)
    s.blocks blk#, -- blocks allocated to the table (still)
    avg_space,     -- bytes free on each block used
    round(s.bytes/1024/1024/1024, 3) space1,
    round(num_rows * avg_row_len * (1 + t.pct_free/100)/ 1024 / 1024 / 1024, 3) space2, -- in mb
    (t.blocks * p.value - t.blocks * t.avg_space) / 1024/ 1024 / 1024  space3 -- in mb
from dba_tables t, dba_segments s, v$parameter p 
where s.owner = t.owner and s.segment_name = t.table_name and table_name = 'TRETADJUSTTRAN' and p.name = 'db_block_size';






select * from user_objects where object_id = tbl$or$idx$part$num(UBRR_ZAA_ACC_REST,0,4,0 ,'1509611753');
select subobject_name from all_objects where data_object_id = 
    (select dbms_rowid.rowid_object(zaa.rowid) from ubrr_zaa_acc_rest partition for ('1509611753') zaa where rownum = 1) and object_type = 'TABLE PARTITION';
	
	
	



-- rollback (undo blocks)

-- Check the estimated time to complete rollback transaction
select 
    usn, state, undoblockstotal blktotal, undoblocksdone blkdone, undoblockstotal-undoblocksdone blktodo, UNDOBLOCKSDONE/UNDOBLOCKSTOTAL*100 pct,
    decode(cputime,0,'unknown',sysdate+(((undoblockstotal-undoblocksdone) / (undoblocksdone / cputime)) / 86400)) "Estimated time to complete"
from v$fast_start_transactions;

-- Check Sid involved in rollback transactions
with source as (
    select 1457 sid, 53213 serial# from dual
)

select s.username,
    s.sid,
    s.serial#,
    t.used_urec,
    t.used_ublk,
    rs.segment_name,
    r.rssize,
    r.status
from source src, 
    v$transaction t,
    v$session s,
    v$rollstat r,
    dba_rollback_segs rs
where src.sid = s.sid and src.serial# = s.serial#
    and s.saddr = t.ses_addr
    and t.xidusn = r.usn
    and rs.segment_id = t.xidusn
order by t.used_ublk desc;





alter session set "_serial_direct_read"=true;

select
count(1)
from TRETADJUSTTRAN TR WHERE TR.BRANCH = 1 AND NOT EXISTS 
(SELECT TD.DOCNO FROM TDOCUMENT TD WHERE TD.BRANCH = TR.BRANCH AND TD.DOCNO = TR.DOCNO);

alter session set "_serial_direct_read"=auto;



select /*+index_ffs(tr PK_RETADJUSTTRAN)*/
count(1)
from TRETADJUSTTRAN TR WHERE TR.BRANCH = 1 AND NOT EXISTS 
(SELECT /*+nj_aj*/ TD.DOCNO FROM TDOCUMENT TD WHERE TD.BRANCH = TR.BRANCH AND TD.DOCNO = TR.DOCNO);



select owner, table_name, num_rows, count(1) from dba_tab_columns join dba_tables using (owner, table_name) group by owner, table_name, num_rows having count(1) > 254 order by 3 desc;

select * from dba_indexes where owner <> table_owner;

select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'9xf8bc1w04q4g', rqeport_level=>'all', type=>'text') SQL_Report from dual;






-- вырезать все из скобок
-- https://community.oracle.com/tech/developers/discussion/2185313/use-regexp-replace-to-blank-out-or-remove-the-parentheses-and-words-in-it
select REGEXP_REPLACE('cardinality(10 ) leading (c  a KOKBF$1@SEL$5 KOKBF$2@SEL$7 b) swap_join_inputs(KOKBF$1@SEL$5  )', '(\[[^]]*?\])|(\([^)]*?\))|(\{[^}]*?\})') from dual;



select sql_id, address, hash_value ,
    'exec sys.dbms_shared_pool.purge(''' || address || ',' || hash_value || ''', ''C'');' x
from v$sqlarea where sql_id = '1sxxfjt9jpgjw';





https://blog.yannickjaquier.com/oracle/plsql-tuning-bulk-sql-parallelism.html




	 
oracle deallocate unused
https://docs.oracle.com/database/121/ARPLS/d_advis.htm#ARPLS65103
https://oracle-base.com/articles/misc/reclaiming-unused-space
https://oracle-base.com/dba/script?category=10g&file=segment_advisor.sql
https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:2049277600346543592
https://docs.oracle.com/database/121/ARPLS/d_space.htm#ARPLS68099
https://docs.oracle.com/database/121/ARPLS/d_space.htm#ARPLS68113
https://docs.oracle.com/cd/E18283_01/server.112/e17120/schema003.htm
https://www.support.dbagenesis.com/post/oracle-segment-advisor
http://www.dba-oracle.com/art_dbazine_idx_rebuild.htm
https://www.navicat.com/en/company/aboutus/blog/1303-how-to-tell-when-it-s-time-to-rebuild-indexes-in-oracle
https://richardfoote.wordpress.com/2011/05/22/del_lf_rows-index-rebuild-criteria-codex/



https://www.oracle.com/technetwork/database/bi-datawarehousing/twp-bp-for-stats-gather-12c-1967354.pdf
https://oracle-base.com/articles/misc/purge-the-shared-pool
https://asktom.oracle.com/pls/apex/f?p=100:11:::::P11_QUESTION_ID:9542428300346881538
https://blog.pythian.com/analyze-index-validate-structure-dark-side/
https://houseofbrick.com/blog/manual-creation-of-a-sql-profile/
https://www.fors.ru/upload/magazine/05/http_texts/russia_ruoug_deev_sql_plans.html
https://asktom.oracle.com/pls/apex/asktom.search?tag=what-is-the-difference-between-shrink-move-and-impdp
https://iusoltsev.wordpress.com/profile/individual-sql-and-cbo/



-- rules to place columns in a table
https://stackoverflow.com/questions/4939735/re-order-columns-of-table-in-oracle

-- histograms
https://oracle-base.com/articles/12c/histograms-enhancements-12cr1

-- context switch
https://fritshoogland.wordpress.com/2016/01/23/plsql-context-switch/
https://fritshoogland.wordpress.com/2016/01/25/plsql-context-switch-part-2/



https://vsadilovskiy.wordpress.com/2007/10/25/tuning-collections-in-queries-1/


https://github.com/tanelpoder/tpt-oracle/blob/master/ash/ash_wait_chains2.sql

https://www.fors.ru/upload/magazine/07/http_text/w_dev_pipelined_tf.html

-- fastest way to concat clob
https://gist.github.com/vlsi/052424856512f80137989c817cb8f046

cardinality feedback
https://iusoltsev.wordpress.com/2013/07/30/cardinality-feedback-high-version-count-same-plan/
https://blogs.oracle.com/optimizer/post/statistics-feedback-formerly-cardinality-feedback







-- sequence usage
select s.sequence_name, round(last_number / (sysdate - created))/24/60 freq_usage_per_min
from user_objects o join user_sequences s on s.sequence_name = o.object_name 
where o.object_name = 'SEQ_UBRR_FSSP_PROTOCOL' and o.object_type = 'SEQUENCE';
--where cache_size = 0 
--order by 1 desc nulls last fetch first 50 row with ties






-- FROM PLAN_TABLE
--explain plan set statement_id = 'dbykov' for ...

select * from table(dbms_xplan.display(statement_id => 'dbykov', format => 'advanced +outline +note'));

select hint
from plan_table pt, 
    xmltable('/other_xml/outline_data/hint/text()' passing xmltype(pt.other_xml) columns hint varchar2(255) path '.')xt 
where pt.plan_id = (select max(plan_id) from plan_table where statement_id = 'dbykov') 
    and pt.id = 1 /*other_xml is not null*/; 

declare
    l_src_sql_id   v$sqlarea.sql_id%type := '3yy6hcyyg0q4g';
    l_statement_id plan_table.statement_id%type := 'dbykov';
    l_sql_profile  varchar2(50) := 'USER_SQLPROF_' || l_src_sql_id;
    --
    l_hints    sys.sqlprof_attr;
    l_sql_text v$sqlarea.sql_fulltext%type;  
begin
    -- новые хинты в настроенном вручную варианте запроса
    select hint
    bulk collect into l_hints
    from plan_table pt, 
        xmltable('/other_xml/outline_data/hint/text()' passing xmltype(pt.other_xml) columns hint varchar2(255) path '.')xt 
    where pt.plan_id = (select max(plan_id) from plan_table where statement_id = l_statement_id) 
        and pt.id = 1; 
        
    -- исходный проблемный запрос
    select sql_fulltext into l_sql_text from v$sqlarea where sql_id = l_src_sql_id and rownum = 1;
    
    -- удаляем профиль, если такой был
    dbms_sqltune.drop_sql_profile(l_sql_profile, ignore => TRUE);

    -- создаем профиль на основе хинтов настроенного варианта
    dbms_sqltune.import_sql_profile(sql_text  => l_sql_text
                                 ,profile     => l_hints
                                 ,category    => 'DEFAULT'
                                 ,name        => l_sql_profile
                                 ,force_match => true);
end;
/

select * from v$sqlarea;

-- FROM MEMORY
select * from table(dbms_xplan.display_cursor(sql_id => '3yy6hcyyg0q4g', cursor_child_no => 0, format => 'advanced +outline +note'));

with source as (
    select '3yy6hcyyg0q4g' sql_id, 3135703986 plan_hash_value, 0 child_number from dual
)
select xt.hint
from source
    join v$sql_plan sp using (sql_id, plan_hash_value, child_number)
    cross join xmltable('/other_xml/outline_data/hint' passing xmltype(sp.other_xml) columns hint varchar2(255) path '.')xt 
where sp.id = 1 /*other_xml is not null*/;


-- FROM HIST
select * from table(dbms_xplan.display_awr(sql_id          => '3yy6hcyyg0q4g', 
                                           plan_hash_value => 3135703986,
                                           db_id           => (select dbid from v$database),
                                           format          => 'advanced +outline +note'));

with source as (
    select '1sxxfjt9jpgjw' sql_id, 4076774282 plan_hash_value from dual
)
select xt.hint
from source
    join dba_hist_sql_plan sp using (sql_id, plan_hash_value)
    cross join xmltable('/other_xml/outline_data/hint' passing xmltype(sp.other_xml) columns hint varchar2(255) path '.')xt 
where sp.id = 1 /*other_xml is not null*/;







-- SQL profile content
with source as (
    select 'SYS_SQLPROF_01516269faab0001' sql_profile_name from dual
)
select 
    sp.name sql_profile_name, sp.status, sp.sql_text, sp.last_modified, spa.comp_data profile_content 
from dba_sql_profiles sp 
    join dbmshsxp_sql_profile_attr spa on spa.profile_name = sp.name
where sp.name in (select sql_profile_name from source);




select * from DBA_OPTSTAT_OPERATION_TASKS 
--    xmltable('/params/param' passing xmltype(notes) columns name varchar2(30) path '@name', 
--                                                            value varchar2(30) path '@val') xt 
                                                            where opid = 18742373 order by start_time desc;
select operation, target, xt.* from DBA_OPTSTAT_OPERATIONS, 
    xmltable('/params/param' passing xmltype(notes) columns name varchar2(30) path '@name', 
                                                            value varchar2(30) path '@val') xt where id = 18742373;
															
															
															
															
															
															
															
-- fix sql plan
select * from dba_sql_plan_baselines;
select * From dba_outlines;
select * From dba_sql_patches;
select * from dba_sql_profiles;
    select * from dbmshsxp_sql_profile_attr;
--    select * from sys.sqlobj$;
--    select * from sys.sqlobj$data;

-- advisor tuning recommendation
select * From dba_advisor_tasks where task_name = 'dbykov_tuning_task';
select * from dba_advisor_recommendations where task_name = 'dbykov_tuning_task';

select * from dba_advisor_sqlplans;
select * from dba_advisor_sqlstats;



-- plan hash_value for baseline
select-- dbms_sqltune_util0.sqltext_to_sqlid(sql_text||chr(0)) sql_id,
( select to_number(regexp_replace(plan_table_output,'^[^0-9]*')) 
  from table(dbms_xplan.display_sql_plan_baseline(sql_handle,plan_name)) 
  where plan_table_output like 'Plan hash value: %') plan_hash_value
,plan_name,enabled,accepted,fixed,reproduced  
,dbms_xplan.format_time_s(elapsed_time/1e6) hours,creator,origin,created,last_modified,last_executed
,sql_text
from dba_sql_plan_baselines b 
where sql_text like '%SELECT NVL(SUM(VALUE),0)%';





-- результаты работы запроса по из SQL MONITOR
select 
    status, sid, sql_exec_id, sql_exec_start, sql_id, sql_plan_hash_value, 
    output_rows, numtodsinterval((last_refresh_time - sql_exec_start),'day') ela,
    (select sql_fulltext from v$sqlarea sa where sa.sql_id = sm.sql_id and sa.plan_hash_value = sm.sql_plan_hash_value) sqltext
from v$sql_plan_monitor sm
where sql_id in ('a7rrnrpm3sk9u') and plan_line_id = 0
order by sql_id, sql_exec_start desc;

select * from table(dbms_xplan.display_cursor ('a7rrnrpm3sk9u'));

select * from v$sql_plan_monitor where sql_id = 'a7rrnrpm3sk9u' and sql_exec_id = 16777298;


col starts for a7
col a_rows for a8
col rwreq for a6
col rwbyt for a9
col max_mem for a8
col id for a3
col sqlplan for a82
with source as (
    select '25ba6pqzmb88d' sql_id, 819029706 plan_hash_value, 17733050 sql_exec_id from dual
)
select 
    decode(t.column_value, 0, null, spm.plan_line_id) id, --sp.parent_id, nullif(sp.depth - 1, -1) depth, 
    -- sql_id, cn = sql child number, hv = plan hash value, ela = elapsed time per seconds, disk = physical read, lio = consistent gets (cr + cu), r = rows processed
    case when t.column_value = 0 and rownum = 1 then --null
            'SQL_ID = ' || spm.sql_id || 
            ', phv = '  || spm.sql_plan_hash_value ||
            ', eid = '  || spm.sql_exec_id 
          when t.column_value = 0 then  
            (select 
                'SQLSTAT: ' ||
                ', e = '    || s.delta_execution_count || 
                ', ela = '  || to_char(round(s.delta_elapsed_time / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') || 
                ', cpu = '  || to_char(round(s.delta_cpu_time / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') || 
                ', io = '   || to_char(round(s.delta_user_io_wait_time / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
                ', cc = '   || to_char(round(s.delta_concurrency_time / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
                ', parse = '|| to_char(round(s.avg_hard_parse_time / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
                ', disk = ' || s.delta_disk_reads ||
                ', lio = '  || s.delta_buffer_gets || 
                ', r = '    || s.delta_rows_processed ||
                ', px = '   || s.delta_px_servers_executions
            from v$sqlstats s where s.sql_id = src.sql_id and s.plan_hash_value = src.plan_hash_value)
          else
        --
        lpad(' ', 4 * spm.plan_depth) || spm.plan_operation || --nvl2(spm.plan_optimizer, '  Optimizer=' || spm.plan_optimizer, null) ||
        nvl2(spm.plan_options, ' (' || spm.plan_options || ')', null) || 
        nvl2(spm.plan_object_name, ' OF ''' || nvl2(spm.plan_object_owner, spm.plan_object_owner || '.', null) || spm.plan_object_name || '''', null) ||
        decode(spm.plan_object_type, 'INDEX (UNIQUE)', ' (UNIQUE)') ||
        '  (Cost=' || spm.plan_cost || ' Card=' || spm.plan_cardinality || ' Bytes=' || spm.plan_bytes || ')'
        end sqlplan, 
    spm.starts,
    spm.output_rows a_rows,
    spm.physical_read_requests + spm.physical_write_requests rwreq,
    spm.physical_read_bytes + spm.physical_write_bytes rwbyt,
    spm.workarea_max_mem max_mem,
    spm.workarea_max_tempseg max_temp
--    ,sp.access_predicates
--    ,sp.filter_predicates
--	,sp.projection
from source src
    left join v$sql_plan_monitor spm on spm.sql_id = src.sql_id and spm.sql_plan_hash_value = src.plan_hash_value and spm.sql_exec_id = src.sql_exec_id
    left join table(sys.odcinumberlist(0,0,1)) t on t.column_value >= spm.plan_line_id
--where s.sql_id = '4m7aatg5uw8sh'
order by spm.sql_plan_hash_value, spm.plan_line_id, t.column_value;



-- health check
https://github.com/vishaldesai/Oracle_Scripts/blob/master/Oracle_DB_HealthCheck_v7.0.1.sql




define grantee ="A4M"
SELECT 'SYSTEM'      typ, 
       grantee       grantee, 
       privilege     priv, 
       admin_option  ad, 
       '--'          tabnm, 
       '--'          colnm, 
       '--'          owner 
FROM   dba_sys_privs 
WHERE  grantee = '&grantee'
UNION 
select 'ROLE'        typ, 
       grantee       grantee, 
       granted_role  priv, 
       admin_option  ad, 
       '--'          tabnm, 
       '--'          colnm, 
       '--'          owner 
from   dba_role_privs 
where  grantee = '&grantee'
union 
SELECT 'TABLE'       typ, 
       grantee       grantee, 
       privilege     priv, 
       grantable     ad, 
       table_name    tabnm, 
       '--'          colnm, 
       owner         owner 
FROM   dba_tab_privs 
WHERE  grantee = '&grantee'
union 
select 'COLNM'       typ, 
       grantee       grantee, 
       privilege     priv, 
       grantable     ad, 
       table_name    tabnm, 
       column_name   colnm, 
       owner         owner 
from   dba_col_privs
where  grantee = '&grantee';








/* DBMS_UTILITY.EXEC_DDL_STATEMENT */
exec DBMS_UTILITY.EXEC_DDL_STATEMENT@remote_db('create table t1 (id number)');


/* UTL_RECOMP */
EXECUTE UTL_RECOMP.RECOMP_PARALLEL(4, 'A4M');

/* DBMS_APPLICATION_INFO */
SET_ACTION Procedure
SET_CLIENT_INFO Procedure
SET_MODULE Procedure
SET_SESSION_LONGOPS Procedure








select ash.session_id sid, ash.session_serial# serial#, min(ash.sample_time) sample_time, ash.sql_id, ash.sql_exec_id, ash.sql_opname, 
    --
    count(1) wait_count, 
    sum(ash.tm_delta_db_time) db_time,
    sum(ash.tm_delta_cpu_time) cpu_time,
    sum(ash.delta_read_io_bytes) rbyt,
    sum(ash.delta_write_io_bytes) wbyt,
    max(ash.pga_allocated) pga,
    max(ash.temp_space_allocated) temp,
    case
        when ash.sql_opcode = 47 then (select object_name || '.' || procedure_name from dba_procedures p where p.object_id = ash.plsql_object_id and p.subprogram_id = ash.plsql_subprogram_id)
        when ash.sql_opcode in (3/*SELECT*/, 85/*TRUNCATE*/) then substr(s.sql_text, 1, 100)
        else '??? (' || to_char(ash.sql_opcode) || ')'
    end subprogram,
    (select o.object_name from dba_objects o where o.object_id = s.program_id) object_name,
    s.program_line#
from v$active_session_history ash
    left join v$sqlarea s on s.sql_id = ash.sql_id
where ash.user_id = 381
group by ash.session_id, ash.session_serial#, ash.sql_id, ash.sql_exec_id, ash.sql_opcode, ash.sql_opname, ash.plsql_object_id, ash.plsql_subprogram_id, 
    s.program_id, s.program_line#, substr(s.sql_text, 1, 100)
order by ash.session_id, ash.session_serial#, sample_time;


select * from v$sqlarea where sql_id = 'bfzkscc39q99t';

select ash.session_id, ash.session_serial#, /*min(ash.sample_time)*/ sample_time, ash.sql_id, ash.sql_exec_id, ash.sql_opname, 'ASH' from v$active_session_history ash where ash.user_id = 381 union all
select m.sid, m.session_serial#, /*min(m.sql_exec_start)*/ sql_exec_start, m.sql_id, m.sql_exec_id,null sql_opname, 'MONITOR' from v$sql_monitor m where m.user# = 381
order by 1,2,3;








-- Oracle EM is the best to identify the usage of CPU and memory used by each session.
-- Moreover use following query to calculate the memory used by the each session.
SELECT to_char(ssn.sid, '9999') || ' - ' || nvl(ssn.username, nvl(bgp.name, 'background')) ||
nvl(lower(ssn.machine), ins.host_name) "SESSION",
to_char(prc.spid, '999999999') "PID/THREAD",
to_char((se1.value/1024)/1024, '999G999G990D00') || ' MB' " CURRENT SIZE",
to_char((se2.value/1024)/1024, '999G999G990D00') || ' MB' " MAXIMUM SIZE"
FROM v$sesstat se1, v$sesstat se2, v$session ssn, v$bgprocess bgp, v$process prc,
v$instance ins, v$statname stat1, v$statname stat2
WHERE se1.statistic# = stat1.statistic# and stat1.name = 'session pga memory'
AND se2.statistic# = stat2.statistic# and stat2.name = 'session pga memory max'
AND se1.sid = ssn.sid
AND se2.sid = ssn.sid
AND ssn.paddr = bgp.paddr (+)
AND ssn.paddr = prc.addr (+);





--- All queries from ASH and SQL MONITOR
with source as (
    select 'ONLINEUSER' username, null sidlist from dual
),
userlist as (
    select u.user_id from dba_users u join source s on s.username = u.username
),
data as (
    select 'ASH' source,
        ash.session_id sid, ash.session_serial# serial, sample_time, ash.sql_id, ash.sql_exec_id, ash.sql_opcode, ash.sql_opname,
        ash.plsql_object_id, ash.plsql_subprogram_id,
        1 rcount,
        ash.tm_delta_db_time ela, 
        ash.tm_delta_cpu_time cpu,
        ash.delta_read_io_bytes rbyt,
        ash.delta_write_io_bytes wbyt,
        ash.pga_allocated pga,
        ash.temp_space_allocated temp,
        sa.sql_text, sa.program_id, sa.program_line# program_line
    from v$active_session_history ash, userlist ul, v$sqlarea sa
    where ash.user_id = ul.user_id 
        and sa.sql_id (+) = ash.sql_id
    union all    
    select 'MONITOR' source,
        m.sid, m.session_serial# serial, m.sql_exec_start sample_time, m.sql_id, m.sql_exec_id, sc.command_type sql_opcode, sc.command_name sql_opname,
        m.plsql_object_id, m.plsql_subprogram_id,
        m.refresh_count rcount,
        m.elapsed_time ela,
        m.cpu_time cpu,
        m.physical_read_bytes rbyt,
        m.physical_write_bytes wbyt,
        null pga,
        null temp, 
        sa.sql_text, sa.program_id, sa.program_line# program_line
    from v$sql_monitor m, userlist ul, v$sqlarea sa, v$sqlcommand sc
    where m.user# = ul.user_id
        and sa.sql_id (+) = m.sql_id
        and sc.command_type (+) = sa.command_type
)
select 
    source,
    sid,
    serial,
    min(sample_time) sample_time,
    sql_id,
    sql_exec_id,
    sql_opname, 
    round(ratio_to_report(sum(ela))over(partition by source, sid, serial) * 100, 2) "pct, %",
    count(rcount) rcount,
    sum(ela)  ela,
    sum(cpu)  cpu,
    sum(rbyt) rbyt,
    sum(wbyt) wbyt,
    max(pga)  pga,
    max(temp) temp,
    substr(sql_text, 1, 100) sql,
    case
        when sql_opcode = 47 then
            (select object_name || '.' || procedure_name from dba_procedures p where p.object_id = d.plsql_object_id and p.subprogram_id = d.plsql_subprogram_id)
        else
            (select o.object_name from dba_objects o where o.object_id = d.program_id) || ' (line: ' || program_line || ')'
    end trace
from data d
group by source,
    sid,
    serial,
    sql_id,
    sql_exec_id, 
    sql_opcode,
    sql_opname,
    substr(sql_text, 1, 100),
    plsql_object_id,
    plsql_subprogram_id,
    program_id, 
    program_line
order by sid, serial, sample_time;
    
    





-- запрос поиска значения по всех полях всех таблиц
with vallist as (select * from table(sys.ku$_objnumset(100,200,300,400))) -- not more than 1000 elements
    ,tbllist as (select owner, table_name, column_name from all_tab_columns where owner = 'A4M' and column_name in ('IDCLIENT', 'ID_CLIENT', 'CLIENTID', 'CLIENT_ID'))
    ,qrylist as (
        select 
            table_name tbl,
            'select 1 x from ' || owner || '.' || table_name || ' where ' || 
            listagg(column_name || ' in ' || 
                (select '(' || listagg(column_value, ',')within group(order by rownum) || ')' from vallist), ' or ')within group(order by column_name) ||
            ' and rownum = 1' sql
        from tbllist
        group by owner, table_name)
        
-- run all queries and show the tables, containing the values from the vallist
select tbl, value(xt).getnumberval() row$ from qrylist, xmltable('/ROWSET/ROW/X/text()' passing dbms_xmlgen.getxmltype(qrylist.sql)) xt;






-- поиск всех запусков dbms_parallel_execute
with jbprfx as (
    select 
        regexp_substr(job_name, '^TASK\$_\d+') job_prefix, count(distinct job_name) job_count, 
        cast(min(req_start_date) as date) job_start_date, 
        min(run_duration) min_duration, max(run_duration) max_duration,
        min(cpu_used) min_cpu_used, max(cpu_used) max_cpu_used
    from dba_scheduler_job_run_details 
    where regexp_like (job_name, '^TASK\$_\d+_\d+$')
    group by regexp_substr(job_name, '^TASK\$_\d+')
)

select 
    jb.*, pet.task_name, pet.sql_stmt 
from jbprfx jb left join dba_parallel_execute_tasks pet 
    on pet.job_prefix = jb.job_prefix
order by trunc(jb.job_start_date) desc, max_cpu_used desc;



-- расшифровка запуской dbms_parallel_execute в разрезе sql_id
with jbprfx as (
    select 
        regexp_substr(job_name, '^TASK\$_\d+') job_prefix,
        req_start_date,
        req_start_date + run_duration,
        (select snap_id from dba_hist_snapshot sn where req_start_date between sn.begin_interval_time and sn.end_interval_time) start_snap_id,
        (select snap_id from dba_hist_snapshot sn where req_start_date+run_duration between sn.begin_interval_time and sn.end_interval_time) stop_snap_id,
        to_number(substr(session_id, 1, instr(session_id, ',')-1)) sid, 
        to_number(substr(session_id, instr(session_id, ',')+1)) serial#
    from dba_scheduler_job_run_details 
    where regexp_like (job_name, '^TASK\$_\d+_\d+$')
--        and job_name like 'TASK$_287458%'
        and trunc(req_start_date) = date'2023-01-26'
)

select 
    jb.job_prefix, jb.start_snap_id, jb.stop_snap_id, ash.sql_id, count(1) rowcount, sum(tm_delta_db_time) db_time, sum(tm_delta_cpu_time) cpu_time
from jbprfx jb join dba_hist_active_sess_history ash 
    on ash.snap_id between jb.start_snap_id and jb.stop_snap_id 
    and ash.session_id = jb.sid 
    and ash.session_serial# = jb.serial#
group by jb.job_prefix, jb.start_snap_id, jb.stop_snap_id, ash.sql_id
order by job_prefix, rowcount desc;
    




-- топ запросов из AWR
with source as (
    select sys.odcivarchar2list('06hg90px1gzhc') sql_id, trunc(sysdate) - 30 btime, trunc(sysdate) + 1 etime from dual
 )
select 
    cn.command_name cn,
    s.sql_id AS sqlid,
    s.plan_hash_value phv,
    count(distinct s.plan_hash_value)over(partition by s.sql_id) pvh#,
    trunc(w.begin_interval_time) AS tl,
    sum(s.executions_delta) AS e,
    round(sum(s.elapsed_time_delta)     / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS ela,
    round(sum(s.cpu_time_delta)         / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS cpu,
    round(sum(s.iowait_delta)           / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS io,
    round(sum(s.ccwait_delta)           / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS cc,
    round(sum(s.apwait_delta)           / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS app,
    round(sum(s.plsexec_time_delta)     / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS plsql,
    round(sum(s.javexec_time_delta)     / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS java,
    round(sum(s.disk_reads_delta)       / greatest(sum(s.executions_delta), 1)) AS disk,
    round(sum(s.buffer_gets_delta)      / greatest(sum(s.executions_delta), 1)) AS lio,
    round(sum(s.rows_processed_delta)   / greatest(sum(s.executions_delta), 1)) AS r,
    round(sum(s.parse_calls_delta)      / greatest(sum(s.executions_delta), 1)) AS pc,
    round(sum(s.px_servers_execs_delta) / greatest(sum(s.executions_delta), 1)) AS px
--    ,trim(to_char(dbms_lob.substr(st.sql_text, 4000))) AS text
from source src,
    dba_hist_sqlstat s,
    dba_hist_snapshot w,
    dba_hist_sqltext st,
    dba_hist_sqlcommand_name cn
where s.snap_id = w.snap_id
    and s.instance_number = w.instance_number
    and s.sql_id = st.sql_id
    and st.command_type = cn.command_type
--    and s.sql_id in (select column_value from table(src.sql_id))
    and w.begin_interval_time between src.btime and src.etime
    and cn.command_name not in ('PL/SQL EXECUTE')
group by trunc(w.begin_interval_time),
    cn.command_name,
    s.sql_id,
    s.plan_hash_value
order by tl desc, ela * decode(sum(s.executions_delta),0,1,sum(s.executions_delta)) desc nulls last;







-- hint validator
with function hint_validator(p_object_owner in all_objects.owner%type,
                             p_object_name  in all_objects.object_name%type,
                             p_object_type  in all_objects.object_type%type) return sys.dm_items is
    --
    c_single_line_comment_init_char  constant varchar2(2) := '--';
    c_multi_line_comment_init_char   constant varchar2(2) := '/*';
    c_multi_line_comment_final_char  constant varchar2(2) := '*/';
    --
    c_single_line_hint_init_char  constant varchar2(3):= '--+';
    c_multi_line_hint_init_char   constant varchar2(3) := '/*+';
    c_multi_line_hint_final_char  constant varchar2(2) := '*/';
    --
    c_undocumented_hint_list  constant sys.odcivarchar2list := sys.odcivarchar2list('PARALLEL');
    --
    l_sposition      integer;
    l_mposition      integer;
    l_mposition_end  integer;
    l_hint_type      varchar2(32);  -- SINGLE | MULTI
    l_raw_hint_list  dbms_sql.varchar2a;
    l_raw_index      binary_integer;
    --
    l_hint_list      sys.dm_items := sys.dm_items();
begin
    for i in (select line, text from all_source s where s.owner = p_object_owner and s.name = p_object_name and s.type = p_object_type)
    loop
        l_sposition := 1;
        l_mposition := 1;
        
        if l_hint_type is null then     
            -- find initial position
            l_sposition := instr(i.text, c_single_line_hint_init_char, 1);
            l_mposition := instr(i.text, c_multi_line_hint_init_char, 1);
            
            if l_sposition > l_mposition then
                l_hint_type := 'SINGLE';
            elsif l_mposition > l_sposition then
                l_hint_type := 'MULTI';
            end if;
        end if;
        
        if l_hint_type = 'SINGLE' then     
            -- add hints to the list
            l_hint_type             := null;
            l_raw_hint_list(i.line) := substr(i.text, l_sposition + length(c_single_line_hint_init_char));
        elsif l_hint_type = 'MULTI' then
            l_mposition_end := instr(i.text, c_multi_line_hint_final_char, l_mposition);
            
            if l_mposition_end > 0 then
                l_hint_type             := null;
                l_raw_hint_list(i.line) := substr(i.text, l_mposition + length(c_multi_line_hint_init_char), l_mposition_end - l_mposition - length(c_multi_line_hint_init_char));
            else
                l_raw_hint_list(i.line) := substr(i.text, l_mposition + length(c_multi_line_hint_init_char));
            end if;
        end if;
    end loop;
    
    l_raw_index := l_raw_hint_list.first;
    while (l_raw_index is not null)
    loop
--        dbms_output.put_line('line ' || l_raw_index || ' : ' || l_raw_hint_list(l_raw_index));
        
        for i in (
            select 
                distinct coalesce(h.name, xt.name) hint, nvl2(h.name, 'VALID', 'INVALID') status
            from xmltable('ora:tokenize(., " ")' passing regexp_replace(l_raw_hint_list(l_raw_index) || ' ', '(\([^)]*?\))') columns name varchar2(32) path '.')xt 
                left join (
                    select name from v$sql_hint 
                    union all 
                    select column_value from table(c_undocumented_hint_list)
                    ) h 
                    on h.name = upper(trim(trim(chr(10) from xt.name)))
            where xt.name is not null
            order by hint
        )
        loop
            l_hint_list.extend;
            l_hint_list(l_hint_list.count) := sys.dm_item(attribute_name      => i.hint, 
                                                          attribute_subname   => i.status,
                                                          attribute_num_value => l_raw_index, 
                                                          attribute_str_value => l_raw_hint_list(l_raw_index));
--            dbms_output.put_line('    ' || i.hint || ' (' || i.status || ')');
        end loop;
        
--        dbms_output.put_line(null);
        
        l_raw_index := l_raw_hint_list.next(l_raw_index);
    end loop;
    
    return l_hint_list;
end hint_validator;

select distinct
    ao.owner,
    ao.object_name,
    hv.attribute_name hint,
    hv.attribute_subname status,
    hv.attribute_num_value line,
    hv.attribute_str_value source
from all_objects ao,
    table(hint_validator(p_object_owner => ao.owner,
                         p_object_name  => ao.object_name,
                         p_object_type  => ao.object_type)) hv
where ao.object_type = 'PACKAGE BODY'
    and ao.owner = 'A4M'
    and ao.object_name like 'SCH_%'
    and hv.attribute_subname = 'INVALID'
order by object_name, line;
/







select sql_id, loaded_versions, parse_calls, parsing_schema_name, is_bind_aware, is_bind_sensitive, sql_text from v$sqlarea where loaded_versions > 1 order by loaded_versions desc;

select 
    sql_id, plan_hash_value, child_number, last_load_time, is_bind_aware, is_bind_sensitive, is_resolved_adaptive_plan, is_shareable, sql_fulltext 
from v$sql
where sql_id = '0hp0xmwwsqyg7';

select count(distinct child_number) from v$sql_shared_cursor where sql_id = '0hp0xmwwsqyg7';








select * from dict where table_name like '%EXTENS%';

select * from sys.col_usage$ where obj# = (select obj# from sys.obj$ where name = 'UBRR_FSSP_CODE_INC_TRN_TWR' and owner# = 64);

select * from sys.col$ where obj# = (select obj# from sys.obj$ where name = 'UBRR_FSSP_CODE_INC_TRN_TWR' and owner# = 64);

select * from dba_stat_extensions where table_name = 'UBRR_FSSP_CODE_INC_TRN_TWR';
select * from dba_tab_col_statistics where table_name = 'UBRR_FSSP_CODE_INC_TRN_TWR';

select * from dba_users order by 1;




-- Средняя скорость плана выполнения
with source as (
    select 'fg35593451dqj' sql_id, trunc(sysdate) - 30 btime, sysdate etime from dual
),
stat as (
    select
        st.*
    from source s
        join dba_hist_snapshot w on w.begin_interval_time between s.btime and s.etime
        join dba_hist_sqlstat st on st.snap_id = w.snap_id
                                and st.dbid = w.dbid
                                and st.instance_number = w.instance_number 
                                and st.sql_id = s.sql_id
)

select 
    sql_id, plan_hash_value, 
    round(avg(db_time)/1e3) avg#, 
    round(min(db_time)/1e3) min#, 
    round(max(db_time)/1e3) max#, 
    count(1) sqlexec
from (
    select 
        s.sql_id, s.plan_hash_value,
        sum(ash.tm_delta_db_time) db_time
    from stat s, dba_hist_active_sess_history ash 
    where s.snap_id = ash.snap_id 
        and s.sql_id = ash.sql_id 
        and s.plan_hash_value = ash.sql_plan_hash_value
    group by s.sql_id, s.plan_hash_value, sql_exec_id,sql_exec_start)
group by sql_id, plan_hash_value;
