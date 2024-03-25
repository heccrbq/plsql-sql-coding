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



-- common info about a TABLE
with source as (
    select 'A4M' table_owner, 'TEXTRACT' table_name from dual
)
select 
    t.owner, table_name, partitioned, num_rows, avg_row_len, 
    t.blocks,      -- blocks contains data (the other block is used by the system)
    empty_blocks,  -- blocks are totally empty (above the HWM)
    s.blocks blk#, -- blocks allocated to the table (still)
    avg_space,     -- bytes free on each block used
    round(s.bytes / 1024 / 1024, 3) allocated_for_segment_mb,
    round(num_rows * avg_row_len * (1 + t.pct_free/100)/ 1024 / 1024, 3) used_by_data_mb,
--    (t.blocks * p.value - t.blocks * t.avg_space) / 1024/ 1024  space3 -- in mb
    round(num_rows * avg_row_len * (1 + t.pct_free/100) / s.bytes * 100, 2) pct_used
from dba_tables t
    join dba_segments s on s.owner = t.owner and s.segment_name = t.table_name
    join v$parameter p on p.name = 'db_block_size'
where (t.owner, t.table_name) in (select * from source);




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




-- owner  : [null | <value>] : for example, 'SYS'
-- fixed : [Y | N] : Y - количество полей, равно сумме количества из attrs, N - количество полей любое, главное, чтоы присутствовали attrs
-- attrs : список типов данных атрибутов, которые должны присутствовать в типе
with source as (
    -- найти тип, владелец которого <ЛЮБОЙ>, в типе 3 поля, 2 из которых имеют типа VARCHAR2, одно поле имеет тип NUMBER
    select null owner, 'Y' fixed, sys.ku$_objnumnamset(sys.ku$_objnumnam(name => 'VARCHAR2', obj_num => 2), 
                                                       sys.ku$_objnumnam(name => 'NUMBER',   obj_num => 1), 
                                                       sys.ku$_objnumnam(name => 'DATE',     obj_num => 0)) attribute from dual
)

select 
    case when upper(s.fixed) = 'Y' then (select sum(obj_num) from table(s.attribute) where obj_num > 0) end number_of_attributes
from source s;

select * from dba_coll_types ct join dba_type_attrs ta on ct.elem_type_name = ta.type_name;

select owner, type_name, package_name, coll_type 
from dba_plsql_coll_types plct 
    join dba_plsql_type_attrs plta on plct.elem_type_owner = plta.type_owner
                                  and plct.elem_type_name = plta.type_name
                                  and plct.elem_type_package = plta.package_name;

select * from dba_plsql_type_attrs;


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
        sql_id, count(distinct sql_exec_id || to_char(sql_exec_start, 'yyyymmddhh24:mi:ss')) unq_run, count(1) rowcount,
        round(sum(tm_delta_db_time)/1e6, 2) db_time, round(sum(tm_delta_cpu_time)/1e6, 2) cpu_time
    from v$active_session_history ash
        join source s on s.sid = ash.session_id and s.serial# = ash.session_serial#
    group by sql_id
    )

select sbq.*, 
    (select owner || '.' || object_name || ' (' || lower(object_type) || ')' from all_objects where object_id = s.program_id) object_name,
    s.program_line#,
    s.* 
from sbq, v$sql s 
where sbq.sql_id = s.sql_id(+)
order by rowcount desc;





select 
    (select
        listagg(
            coalesce(
                -- 1
                dbms_xmlgen.convert(
                    xmlquery('for $i in //*
                        return $i/text()' 
                        passing dbms_xmlgen.getxmltype(
                            'select column_expression from dba_ind_expressions 
								where index_owner = ''' || ic.index_owner || '''
                                  and index_name  = ''' || ic.index_name  || '''
                                  and column_position = ''' || ic.column_position || '''') returning content 
                      ).getstringval(),1),
                -- 2
                ic.column_name
            ),
        ', ')within group(order by ic.column_position)
    from dba_ind_columns ic where ic.index_owner = sp.object_owner and ic.index_name = sp.object_name) column_list,
    sp.access_predicates,
    sp.filter_predicates,
    sp.sql_id,
    sp.object_owner index_owner,
    sp.object_name  index_name
from v$sql_plan sp
where operation = 'INDEX' and options = 'RANGE SCAN' and sp.object_owner = 'A4M';








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




select xt.* 
from v$sql_monitor, 
    xmltable('/binds/bind' passing xmltype(binds_xml) 
        columns name   varchar2(7)  path '@name',
                pos    number       path '@pos',
                dty    number       path '@dty',
                dtystr varchar2(15) path '@dtystr',
                maxlen number       path '@maxlen',
                len    number       path '@len',
                value  varchar2(25) path '.')xt 
where sql_id = '7rm05gzgtjwcw' and sql_exec_id = 16777216;








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
col a_time for a20
col rwreq for a6
col rwbyt for a10
col max_mem for a12
col id for a3
col sqlplan for a140
with source as (
    select '4r9pgtqdqbsxm' sql_id, 2781946110 plan_hash_value, 16777232 sql_exec_id from dual
)
--select * from v$sql_plan_monitor natural join source;
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
    lpad(to_char(round(
        (spm.last_change_time - spm.first_change_time) / 
        max((spm.last_change_time - spm.first_change_time))over(partition by spm.sql_id, spm.sql_plan_hash_value, spm.sql_exec_id) * 100, 2), 'fm990D00'), 6) || ' %' pct_usage,
    spm.starts,
    spm.output_rows a_rows,
    numtodsinterval((spm.last_change_time - spm.first_change_time), 'day') a_time,
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










col name for a7
col value_string for a20
select name, position, datatype_string, was_captured, last_captured, value_string from v$sql_bind_capture where sql_id = 'b6hxtabrrdxqw';



col hist for a78
col sqlplan for a203
with source as 
(
    select 'b6hxtabrrdxqw' sql_id, 2881119326 plan_hash_value, 16777216 sql_exec_id, 133 snap_id_from, 134 snap_id_to from dual
),
settings as 
(
    select 0 enable_events from dual
),
ash as
(   -- строки с sql_exec_id is null and in_parse = 'Y' and in_hard_parse = 'Y' учтены в ASH: parse - в это время происходит парсинг запроса.
    select /*+materialize*/
        ash.*
    from dba_hist_active_sess_history ash
		join source s on ash.sql_id = s.sql_id 
					 and ash.sql_plan_hash_value = s.plan_hash_value 
					 and ash.sql_exec_id = s.sql_exec_id
					 and ash.snap_id between s.snap_id_from and s.snap_id_to
)

-- Статистика выполнения запроса по sql_id и plan_hash_value из dba_hist_sqlstat
select
    null id,
--    null parent_id,
--    null depth,
    'SQLSTAT: ' ||
    'SQL_ID = ' || st.sql_id || 
    ', hv = '   || st.plan_hash_value ||
    ', e = '    || sum(st.executions_delta) || 
    ', ela = '  || to_char(round(sum(st.elapsed_time_delta) / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') || 
    ', cpu = '  || to_char(round(sum(st.cpu_time_delta)     / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') || 
    ', io = '   || to_char(round(sum(st.iowait_delta)       / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', disk = ' || round(sum(st.disk_reads_delta)           / greatest(sum(st.executions_delta), 1)) ||
    ', lio = '  || round(sum(st.buffer_gets_delta)          / greatest(sum(st.executions_delta), 1)) || 
    ', r = '    || round(sum(st.rows_processed_delta)       / greatest(sum(st.executions_delta), 1)) ||
    ', px = '   || round(sum(st.px_servers_execs_delta)     / greatest(sum(st.executions_delta), 1)) sqlplan,
    null ash_count,
    to_char(round(sum(st.elapsed_time_delta) / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ela,
    null db_time,
    to_char(round(sum(st.cpu_time_delta)     / greatest(sum(st.executions_delta), 1) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') cpu_time,
    null px,
    null tmp,
    null pga,
    null undo,
    null hist
from dba_hist_sqlstat st
where (st.sql_id, st.plan_hash_value) in (select sql_id, plan_hash_value from source)
    and (st.instance_number, st.snap_id) in 
        (select 
            s.instance_number, s.snap_id 
        from dba_hist_snapshot s 
        where s.snap_id in 
            (select /*+no_merge */ distinct ash.snap_id from ash))
group by st.sql_id, st.plan_hash_value
union all
-- Статистика конкретного SQL_EXEC_ID в разрезе точечных snap_id
select
    null id,
--    null parent_id,
--    null depth,
    'ASH: ' ||
    'SQL_EXEC_ID = ' || ash.sql_exec_id ||
    ', from = ' || ash.sql_exec_start ||
    ', parse = ' || 
        to_char(
            round(
                (select 
                    sum(h.tm_delta_time) / 1e6
                from dba_hist_active_sess_history h 
                where h.sql_id = ash.sql_id and h.sql_plan_hash_value = ash.sql_plan_hash_value and h.session_id = ash.session_id and h.session_serial# = ash.session_serial#
                    -- нужен between между snap_id_from и snap_id_to
					and h.snap_id = (select min(ash.snap_id) from ash)
                    and h.in_parse = 'Y' and h.in_hard_parse = 'Y')
            , 2)
        , 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', ela = '  || to_char(round(sum(ash.tm_delta_time)     / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', db = '  || to_char(round(sum(ash.tm_delta_db_time)  / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', cpu = ' || to_char(round(sum(ash.tm_delta_cpu_time) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', waiting (%) = '  || to_char(round(count(decode(ash.session_state, 'WAITING', 1)) / count(1) * 100, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ||
    ', on cpu (%) = '  || to_char(round(count(decode(ash.session_state, 'ON CPU', 1)) / count(1) * 100, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') sqlplan,
    count(1) ash_count,
    to_char(round(sum(ash.tm_delta_time)     / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ela,
    to_char(round(sum(ash.tm_delta_db_time)  / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') db_time,
    to_char(round(sum(ash.tm_delta_cpu_time) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') cpu_time,
    null px,
    null tmp,
    null pga,
    count((select df.relative_fno from dba_data_files df join dba_tablespaces dt on df.tablespace_name = dt.tablespace_name where dt.contents = 'UNDO' and df.relative_fno = ash.current_file#)) undo,
    null hist
from ash
group by ash.sql_id, ash.sql_plan_hash_value, ash.sql_exec_id, ash.sql_exec_start, ash.session_id, ash.session_serial#
union all
select
    sp.id, --sp.parent_id, nullif(sp.depth - 1, -1) depth, 
    lpad(' ', 4*depth) || sp.operation || nvl2(sp.optimizer, '  Optimizer=' || sp.optimizer, null) ||
    nvl2(sp.options, ' (' || sp.options || ')', null) || 
    nvl2(sp.object_name, ' OF ''' || nvl2(sp.object_owner, sp.object_owner || '.', null) || sp.object_name || '''', null) ||
    decode(sp.object_type, 'INDEX (UNIQUE)', ' (UNIQUE)') ||
    '  (Cost=' || cost || ' Card=' || sp.cardinality || ' Bytes=' || bytes || ')' sqlplan,
    ash.ash_count,
    to_char(round(ash.tm_time  / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ela,
    to_char(round(ash.db_time  / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') db_time,
    to_char(round(ash.cpu_time / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') cpu_time,
    ash.px,
    ash.tmp,
    ash.pga,
    ash.undo,
    to_char(round(100 * ratio_to_report(ash.db_time)over(), 2), 'fm00D00', 'nls_numeric_characters = ''.,') ||
        case when ash.db_time is not null then
            '%(cpu ' || to_char(round(100 * ash.cpu_time/ash.db_time, 2), 'fm00D00', 'nls_numeric_characters = ''.,') || '%' ||
            ' wait ' || to_char(round(100 * (ash.db_time - ash.cpu_time)/ash.db_time, 2), 'fm00D00', 'nls_numeric_characters = ''.,') || '%)'
        end  ||
        case when ratio_to_report(ash.db_time)over() >= 0.005 then rpad(' ', 1 + round(100 * ratio_to_report(ash.db_time)over()), '*') end hist
from dba_hist_sql_plan sp
    left join
        (select /*+*no_merge*/
            ash.sql_id,
            ash.sql_plan_hash_value,
            ash.sql_plan_line_id,
            count(1) ash_count,
            sum(ash.tm_delta_time) tm_time,
            sum(ash.tm_delta_db_time) db_time,
            sum(ash.tm_delta_cpu_time) cpu_time,
            count(distinct qc_session_id) px,
            round(max(temp_space_allocated)/1024/1024, 3) tmp,
            round(max(pga_allocated)/1024/1024, 3) pga,
            count((select df.relative_fno from dba_data_files df join dba_tablespaces dt on df.tablespace_name = dt.tablespace_name where dt.contents = 'UNDO' and df.relative_fno = ash.current_file#)) undo
        from ash
        group by ash.sql_id,
            ash.sql_plan_hash_value,
            ash.sql_plan_line_id) ash 
    on ash.sql_id = sp.sql_id
        and ash.sql_plan_hash_value = sp.plan_hash_value
        and ash.sql_plan_line_id = sp.id
where (sp.sql_id, sp.plan_hash_value) in (select sql_id, plan_hash_value from source)
union all
select
    ash.sql_plan_line_id id,
--    null parent_id,
--    null depth,
    lpad('| ', 2 + (select 4*(sp.depth+1) from dba_hist_sql_plan sp where sp.sql_id = ash.sql_id and sp.plan_hash_value = ash.sql_plan_hash_value and sp.id = ash.sql_plan_line_id)) || 
    rpad(lower(ash.session_state), 7) || ' | ' ||  
    rpad(coalesce(ash.event, ' '), max(length(ash.event))over(partition by ash.sql_plan_line_id)) || ' | ' || 
    lpad(to_char(round((ratio_to_report(count(1)) over (partition by ash.sql_plan_line_id))*100, 2), 'fm999G990D00', 'nls_numeric_characters=''. '''), 5) || '% |' as top_event,
    count(1) ash_count,
    to_char(round(sum(ash.tm_delta_time)     / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') ela,
    to_char(round(sum(ash.tm_delta_db_time)  / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') db_time,
    to_char(round(sum(ash.tm_delta_cpu_time) / 1e6, 2), 'fm999G990D00', 'nls_numeric_characters=''. ''') cpu_time,
    count(distinct ash.qc_session_id) px,
    round(max(temp_space_allocated)/1024/1024, 3) tmp,
    round(max(pga_allocated)/1024/1024, 3) pga,
    count((select df.relative_fno from dba_data_files df join dba_tablespaces dt on df.tablespace_name = dt.tablespace_name where dt.contents = 'UNDO' and df.relative_fno = ash.current_file#)) undo,
    null hist
from ash
where exists (select 0 from settings where enable_events = 1)
group by ash.sql_id,
    ash.sql_plan_hash_value,
    ash.sql_plan_line_id,
    ash.session_state, 
    ash.event
order by id nulls first, /*parent_id, */sqlplan desc;












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
    substr(s.sql_text, 1, 100) subprogram,
--    case
--        when ash.sql_opcode = 47 then (select object_name || '.' || procedure_name from dba_procedures p where p.object_id = ash.plsql_object_id and p.subprogram_id = ash.plsql_subprogram_id)
--        when ash.sql_opcode in (3/*SELECT*/, 85/*TRUNCATE*/) then substr(s.sql_text, 1, 100)
--        else '??? (' || to_char(ash.sql_opcode) || ')'
--    end subprogram,
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





-- Все запрос по сессии из HIST'a
select 
    ash.sql_id, 
    -- plan count
    (select count(distinct plan_hash_value) from dba_hist_sql_plan st where st.sql_id = ash.sql_id) awr,
    (select count(distinct plan_hash_value) from v$sql_plan st where st.sql_id = ash.sql_id) mem,
    (select count(distinct sql_plan_hash_value) from v$sql_plan_monitor st where st.sql_id = ash.sql_id) mon,
    --
    count(1) rowcount, count(1)*10 total_time, round(ratio_to_report(count(1))over(partition by nvl2(ash.sql_id,1,0)) * 100, 2) pct, 
    count(distinct sql_exec_id || to_char(sql_exec_start, 'yyyymmddhh24:mi:ss')) unq_run, 
    round(count(1)/greatest(count(distinct sql_exec_id || to_char(sql_exec_start, 'yyyymmddhh24:mi:ss')), 1), 2)*10  avg_sec,
    coalesce(
        (select to_char(substr(sql_text,1, 100)) from dba_hist_sqltext sq join v$database using(dbid) where sql_id = ash.sql_id),
        (select to_char(substr(sql_text,1, 100)) from v$sqlarea sa where sa.sql_id = ash.sql_id and rownum = 1)
    )sql_text
from dba_hist_active_sess_history ash
--    join dba_hist_snapshot s using(snap_id)
where (session_id, session_serial#) in ((4840,11850))
--    and begin_interval_time >= sysdate - 14
    and ash.sql_id is not null
group by grouping sets((sql_id),null)
order by rowcount desc nulls last;







--- All queries from ASH and SQL MONITOR
col SQL_OPNAME for a15
col trace for a40
with source as (
    select 'MEZENCEVA' username, sys.ku$_objnumpairlist(sys.ku$_objnumpair(num1 => 235/*sid*/, num2 => 2508/*serial#*/)) sidlist from dual
),
userlist as (
    select u.user_id, sidlist from dba_users u join source s on s.username = u.username
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
        and (ash.session_id, ash.session_serial#) in (select num1, num2 from table(ul.sidlist))
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
        and (m.sid, m.session_serial#) in (select num1, num2 from table(ul.sidlist))
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






-- ПЛаны выполнения 
with source as (
    select trunc(sysdate) - 30 btime, sysdate etime from dual
),
stat as (
    select
        *
    from source s
        join dba_hist_snapshot w on w.begin_interval_time between s.btime and s.etime
        join dba_hist_sqlstat st on st.snap_id = w.snap_id
                                and st.dbid = w.dbid
                                and st.instance_number = w.instance_number 
                                and st.sql_id = 'fg35593451dqj'
    where st.plan_hash_value <> 0
)
select 
    st.sql_id, 
    count(distinct st.plan_hash_value) loaded_plans, 
    cast(max(st.begin_interval_time) as date) last_load_time,
    min(st1.ela) min_elapsed,
    max(st1.ela) max_elapsed,
    round(decode(min(st1.ela), 0, 0, abs(1 - max(st1.ela) / min(st1.ela))) * 100) percent
from stat st
    left join (
        select
            sql_id, 
            plan_hash_value, 
            round(sum(elapsed_time_delta) / greatest(sum(executions_delta), 1) / 1e6, 4) AS ela
        from stat
        group by sql_id,
            plan_hash_value
    ) st1 on st1.sql_id = st.sql_id
group by st.sql_id
having count(distinct st.plan_hash_value) > 1
order by percent desc;



-- #
with source as (
    select sys.odcivarchar2list('b94nr0swdgxcy') sql_id, trunc(sysdate) - 30 btime, sysdate + 1 etime from dual
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
    ,trim(to_char(dbms_lob.substr(st.sql_text, 4000))) AS text
from source src,
    dba_hist_sqlstat s,
    dba_hist_snapshot w,
    dba_hist_sqltext st,
    dba_hist_sqlcommand_name cn
where s.snap_id = w.snap_id
    and s.instance_number = w.instance_number
    and s.sql_id = st.sql_id
    and st.command_type = cn.command_type
    and s.sql_id in (select column_value from table(src.sql_id)t)
    and w.begin_interval_time between src.btime and src.etime
    and cn.command_name not in ('PL/SQL EXECUTE', 'CALL METHOD')
group by trunc(w.begin_interval_time),
    cn.command_name,
    s.sql_id,
    s.plan_hash_value
    ,trim(to_char(dbms_lob.substr(st.sql_text, 4000)))
order by tl desc, ela * greatest(e,1) desc nulls last;



-- Количество планов выполнения и их скорость работы
with source as (
    select '0mcrtafb6b09x' sql_id, trunc(sysdate) - 30 btime, sysdate etime from dual
)

select
    st.sql_id, st.plan_hash_value,
    sum(st.executions_delta) AS e,
    round(sum(st.elapsed_time_delta) / greatest(sum(st.executions_delta), 1) / 1e3, 4) AS ela
from source s
    join dba_hist_snapshot w on w.begin_interval_time between s.btime and s.etime
    join dba_hist_sqlstat st on st.snap_id = w.snap_id
                            and st.dbid = w.dbid
                            and st.instance_number = w.instance_number 
                            and st.sql_id = s.sql_id
group by st.sql_id, st.plan_hash_value;


with source as (
    select '0mcrtafb6b09x' sql_id, trunc(sysdate) - 30 btime, sysdate etime from dual
),
stat as (
    select
        st.snap_id, st.sql_id, st.plan_hash_value, st.instance_number
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
    round(stddev(db_time)/1e3) stddev#, 
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
        and s.instance_number = ash.instance_number 
    group by s.sql_id, s.plan_hash_value, sql_exec_id,sql_exec_start)
group by sql_id, plan_hash_value;







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


-- CPU Utilization
SELECT *
FROM (
       SELECT instance_number
            , LAG(snap_id, 1, 0) OVER(PARTITION BY dbid, instance_number ORDER BY snap_id) first_snap_id
            , snap_id second_snap_id
            , begin_time
            , end_time
            , metric_name
            , metric_unit
            , ROUND(average, 2) || '%' awr_cpu_usage
       FROM dba_hist_sysmetric_summary
       WHERE metric_name = 'Host CPU Utilization (%)'
       ORDER BY instance_number
              , first_snap_id
     )
WHERE first_snap_id <> 0;



-- column usage

-- light version
select o.name table_name, c.name column_name, 
    u.equality_preds, u.equijoin_preds, u.nonequijoin_preds, u.range_preds, u.like_preds, u.null_preds
from sys.col_usage$ u, sys.obj$ o, sys.col$ c
where u.obj# = o.obj# and c.obj# = o.obj# and u.intcol# = c.intcol#
    and o.name = 'UBRR_SAA_DBVREQUEST';
    
-- hard version
select o.name table_name, c.name column_name, 
    u.equality_preds, u.equijoin_preds, u.nonequijoin_preds, u.range_preds, u.like_preds, u.null_preds,
--    t.density, 
    t.num_distinct, t.num_nulls, t.num_buckets, t.histogram
--    (select 
--        listagg(ic.index_name, ', ')within group(order by ic.index_name)
--    from dba_ind_columns ic
--    where ic.column_name = c.name
--        and ic.table_name = o.name) uses_in_indexes
from sys.col_usage$ u, sys.obj$ o, sys.col$ c, dba_tab_columns t
where u.obj# = o.obj# and c.obj# = o.obj# and u.intcol# = c.intcol# and o.name = t.table_name and c.intcol# = t.column_id
    and o.name = 'TIDENTITY';
    
    
    
    
    
select i.table_name, i.index_name, i.num_rows, c.column_name, u.timestamp
from user_indexes i 
    join user_ind_columns c 
        on i.index_name = c.index_name
    left join (
        select o.name table_name, c.name column_name, u.* from sys.col_usage$ u, sys.obj$ o, sys.col$ c 
        where u.obj# = o.obj# and c.obj# = o.obj# and u.intcol# = c.intcol#
--            and o.name = 'TREPGL152_UBRR_CHECK'
            ) u 
        on u.table_name = c.table_name and u.column_name = c.column_name
--where i.table_name = 'TREPGL152_UBRR_CHECK';
where u.timestamp is null and i.table_name like '%UBRR%' and i.table_name not like 'TTX%'
order by i.num_rows desc nulls last;





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



-- session top by db time and cpu time
select 
    s.sid, s.status, s.schemaname, s.logon_time,
    sum(tm.value)/1e6 db_time_sec,
    to_char(round(ratio_to_report(sum(tm.value))over() * 100, 2), '990D00') || ' %' db_pct,
    sum(tm2.value)/1e6 cpu_time_sec,
    to_char(round(ratio_to_report(sum(tm2.value))over() * 100, 2), '990D00') || ' %' cpu_pct    
from gv$session s 
    left join gv$sess_time_model tm on s.inst_id = tm.inst_id and s.sid = tm.sid and tm.stat_name = 'DB time'
    left join gv$sess_time_model tm2 on s.inst_id = tm2.inst_id and s.sid = tm2.sid and tm2.stat_name = 'DB CPU'
group by s.sid, s.status, s.schemaname, s.logon_time
order by db_pct desc, 
    cpu_pct desc;




-- 10053 trace using specified sql_id
-- сначала надо его через purge выгрузить из library cache, чтобы заставить пойти на hard parse_calls
-- затем через alter system отлавливать его разбор
select sql_id, address, hash_value ,
    'exec sys.dbms_shared_pool.purge(''' || address || ',' || hash_value || ''', ''C'');' x
from v$sqlarea where sql_id in ('96h9m0f2ud62q','a9kmw17pq43dv','f6h72xnjb16tf','7amf1f35g3nrp');

alter system set events 'trace[rdbms.SQL_Optimizer.*][sql:96h9m0f2ud62q]';

alter system set events 'trace[rdbms.SQL_Optimizer.*][sql:96h9m0f2ud62q] off';






-- параметры автоматического сбора статистики(по умолчанию): dbsm_stats
-- https://iusoltsev.wordpress.com/profile/individual-sql-and-cbo/statistics/
select sname, spare4 from sys.optstat_hist_control$ order by 1;

select
 DBMS_STATS.GET_PREFS ('AUTOSTATS_TARGET')        as AUTOSTATS_TRGT,
 DBMS_STATS.GET_PREFS ('CASCADE')                 as CASCADE,
 DBMS_STATS.GET_PREFS ('DEGREE')                  as DEGREE,
 DBMS_STATS.GET_PREFS ('ESTIMATE_PERCENT')        as ESTIMATE_PRCNT,
 DBMS_STATS.GET_PREFS ('METHOD_OPT')              as METHOD_OPT,
 DBMS_STATS.GET_PREFS ('NO_INVALIDATE')           as NO_INVALIDATE,
 DBMS_STATS.GET_PREFS ('GRANULARITY')             as GRANULARITY,
 DBMS_STATS.GET_PREFS ('PUBLISH')                 as PUBLISH,
 DBMS_STATS.GET_PREFS ('INCREMENTAL')             as INCREMENTAL,
 DBMS_STATS.GET_PREFS ('INCREMENTAL_LEVEL')       as INCREMENTAL_LEVEL,
 DBMS_STATS.GET_PREFS ('INCREMENTAL_STALENESS')   as INCREMENT_STALENESS,
 DBMS_STATS.GET_PREFS ('STALE_PERCENT')           as STALE_PERCENT,
 DBMS_STATS.GET_PREFS ('TABLE_CACHED_BLOCKS')     as TABLE_CACHED_BLOCKS,
 DBMS_STATS.GET_PREFS ('GLOBAL_TEMP_TABLE_STATS') as GLOBAL_TEMP_TABLE_STATS,
 DBMS_STATS.GET_PREFS ('OPTIONS')                 as OPTIONS
 from dual;




-- 10053 trace запроса, который уже есть в library cache без его выгрузки из кэша
-- параметры: sql_id, child_number, хз, tracefile_identifier
exec dbms_sqldiag.dump_trace('96h9m0f2ud62q',0,'Optimizer','TWR_2603_96h9m0f2ud62q');

select * from GV$DIAG_TRACE_FILE where trace_filename like '%TWR_2603%' order by change_time desc;

select 
    dbms_xmlgen.convert(xmlagg(xmlelement(r, payload)).extract('//text()').getclobval(),1)
from v$diag_trace_file_contents 
where trace_filename = 'ytwr_ora_13107434_TWR_2603_96h9m0f2ud62q.trc';


select * from GV$DIAG_TRACE_FILE order by change_time desc;



-- PREFS

exec dbms_stats.set_table_prefs('A4M','TREPY21RESULTS_127','ESTIMATE_PERCENT','10');
select dbms_stats.get_prefs('ESTIMATE_PERCENT','A4M','TREPY21RESULTS_127') from dual;
select * From DBA_TAB_STAT_PREFS where table_name = 'TREPY21RESULTS_127';


/*********************  FAKE BASELINE ***********************/

-- #1. Нужно чтобы оба запроса были загружены в shared pool
--     l_source_sql_id   -  исходный запрос с плохих планом
--     l_target_sql_id   -  целевой запрос с хорошим планом
--     l_targer_sql_phv  -  хороший план целевого запроса
set serveroutput on size unl
declare
    l_source_sql_id  v$sqlarea.sql_id%type := 'sourcequery';
    l_target_sql_id  v$sqlarea.sql_id%type := 'targetquery';
    l_targer_sql_phv v$sqlarea.plan_hash_value%type := 1234567890;
    l_sql_fulltext   v$sqlarea.sql_fulltext%type;
begin
    select sql_fulltext
    into l_sql_fulltext
    from v$sqlarea
    where sql_id = l_source_sql_id
        and rownum = 1;
 
    dbms_output.put_line(
        dbms_spm.load_plans_from_cursor_cache(
            sql_id          => l_target_sql_id,
            plan_hash_value => l_targer_sql_phv,
            sql_text        => l_sql_fulltext,
            fixed           => 'NO',
            enabled         => 'YES'
        )
    ); 
end;
/




set serveroutput on size unl
begin   
      dbms_output.put_line(
          dbms_spm.load_plans_from_awr(begin_snap => 119632,
                                       end_snap =>   119633,
                                       basic_filter => q'[ sql_id='bx8tzzxp058cd' and plan_hash_value='2977621182' ]',
              fixed           => 'NO',
              enabled         => 'YES'
          )
      ); 
end;
/

select * from dba_sql_plan_baselines where to_char(substr(sql_text,1,4000)) = (select to_char(substr(sql_text,1,4000)) from dba_hist_sqltext where sql_id = 'bx8tzzxp058cd');















-- https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:707586567563
Tom, in 9i is WIDTH_BUCKET function useful to generate info about skewed data? If so, any example you have? Thanks.

Tom Kyte
February 20, 2004 - 1:30 pm UTC
it is a tool you can use to measure "skewedness".   for example:


ops$tkyte@ORA920PC> select min(object_id), max(object_id), count(object_id), wb
  2    from (
  3  select object_id,
  4         width_bucket( object_id,
  5                       (select min(object_id)-1 from all_objects),
  6                       (select max(object_id)+1 from all_objects), 5 ) wb
  7    from all_objects
  8         )
  9   group by wb
 10  /
 
MIN(OBJECT_ID) MAX(OBJECT_ID) COUNT(OBJECT_ID)         WB
-------------- -------------- ---------------- ----------
             3           8639             7972          1
          8640          17277             8638          2
         17278          25915             8619          3
         25916          34528             4751          4
         35159          43191              238          5
 

shows that if I bucketize into 5 buckets, most of my data is "low" 1,2,3.  object_ids over 26k are "few and far between"

it is an analysis tool you can use to see what you have. 





/** SQL TUNING ADVISOR by SQL_ID **/
set timing on
set serveroutput on size unl
declare
    l_jira_task varchar2(30) := 'TWR-436';
    l_sql_id    v$sql.sql_id%type := 'd9vx45z6jq89b';
    l_author    varchar2(255) := sys_context('userenv','os_user');
    l_sql_tune_task_id varchar2(100);
begin
    l_sql_tune_task_id := dbms_sqltune.create_tuning_task (
        sql_id      => l_sql_id,
        scope       => dbms_sqltune.scope_comprehensive,
        time_limit  => 500,
        task_name   => l_sql_id || '_tuning_task',
        description => 'Tuning task for statement ' || l_sql_id || ' created by ' || l_author ||' within the ' || l_jira_task || ' jira task.');
        
    dbms_output.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
end;
/

exec dbms_sqltune.execute_tuning_task(task_name => 'd9vx45z6jq89b_tuning_task');

select dbms_sqltune.report_tuning_task('d9vx45z6jq89b_tuning_task') from dual;

--exec dbms_sqltune.drop_tuning_task('d9vx45z6jq89b_tuning_task');



/** SQL ACCESS ADVISOR by SQL_ID **/
set timing on
set serveroutput on size unl
DECLARE
    l_sql_id v$sql.sql_id%type := 'd9vx45z6jq89b';    
    l_task_name varchar2(30) := 'SQLAccessAdv_d9vx45z6jq89b';
    l_task_desc varchar2(256) := 'Access task for statement d9vx45z6jq89b created by u00033859 within the TWR-4051 jira task.';
    l_task_or_template varchar2(30) := 'SQLACCESS_EMTASK';
    --
    l_task_id number := 0;
    l_num_found number;
    l_sts_name varchar2(256) := 'SQLAccessAdv_d9vx45z6jq89b_STS';
    l_sts_cursor dbms_sqltune.sqlset_cursor;
BEGIN
  /* Create Task */
  dbms_advisor.create_task(DBMS_ADVISOR.SQLACCESS_ADVISOR,
                           l_task_id,
                           l_task_name,
                           l_task_desc,
                           l_task_or_template);

  /* Reset Task */
  dbms_advisor.reset_task(l_task_name);

  /* Delete Previous STS Workload Task Link */
  select count(*)
  into   l_num_found
  from   user_advisor_sqla_wk_map
  where  task_name = l_task_name
  and    workload_name = l_sts_name;
  IF l_num_found > 0 THEN
    dbms_advisor.delete_sqlwkld_ref(l_task_name,l_sts_name,1);
  END IF;

  /* Delete Previous STS */
  select count(*)
  into   l_num_found
  from   user_advisor_sqlw_sum
  where  workload_name = l_sts_name;
  IF l_num_found > 0 THEN
    dbms_sqltune.delete_sqlset(l_sts_name);
  END IF;

  /* Create STS */
  dbms_sqltune.create_sqlset(l_sts_name, 'Obtain workload from cursor cache');

  /* Select all statements in the cursor cache. */
  OPEN l_sts_cursor FOR
    SELECT VALUE(P)
    FROM TABLE(dbms_sqltune.select_cursor_cache) P
    WHERE VALUE(P).SQL_ID = l_sql_id;

  /* Load the statements into STS. */
  dbms_sqltune.load_sqlset(l_sts_name, l_sts_cursor);
  CLOSE l_sts_cursor;

  /* Link STS Workload to Task */
  dbms_advisor.add_sqlwkld_ref(l_task_name,l_sts_name,1);

  /* Set STS Workload Parameters */
  dbms_advisor.set_task_parameter(l_task_name,'VALID_ACTION_LIST',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'VALID_MODULE_LIST',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'SQL_LIMIT','25');
  dbms_advisor.set_task_parameter(l_task_name,'VALID_USERNAME_LIST',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'VALID_TABLE_LIST',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'INVALID_TABLE_LIST',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'INVALID_ACTION_LIST',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'INVALID_USERNAME_LIST',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'INVALID_MODULE_LIST',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'VALID_SQLSTRING_LIST',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'INVALID_SQLSTRING_LIST','"@!"');

  /* Set Task Parameters */
  dbms_advisor.set_task_parameter(l_task_name,'ANALYSIS_SCOPE','ALL');
  dbms_advisor.set_task_parameter(l_task_name,'RANKING_MEASURE','PRIORITY,OPTIMIZER_COST');
  dbms_advisor.set_task_parameter(l_task_name,'DEF_PARTITION_TABLESPACE',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'TIME_LIMIT',10000);
  dbms_advisor.set_task_parameter(l_task_name,'MODE','LIMITED');
  dbms_advisor.set_task_parameter(l_task_name,'STORAGE_CHANGE',DBMS_ADVISOR.ADVISOR_UNLIMITED);
  dbms_advisor.set_task_parameter(l_task_name,'DML_VOLATILITY','TRUE');
  dbms_advisor.set_task_parameter(l_task_name,'WORKLOAD_SCOPE','PARTIAL');
  dbms_advisor.set_task_parameter(l_task_name,'DEF_INDEX_TABLESPACE',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'DEF_INDEX_OWNER',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'DEF_MVIEW_TABLESPACE',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'DEF_MVIEW_OWNER',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'DEF_MVLOG_TABLESPACE',DBMS_ADVISOR.ADVISOR_UNUSED);
  dbms_advisor.set_task_parameter(l_task_name,'CREATION_COST','TRUE');
  dbms_advisor.set_task_parameter(l_task_name,'JOURNALING','4');
  dbms_advisor.set_task_parameter(l_task_name,'DAYS_TO_EXPIRE','30');

  /* Execute Task */
  dbms_advisor.execute_task(l_task_name);
END;
/






-- statistics, history of stats
with source as (
    select distinct object_owner, object_name, object_type From v$sql_plan where sql_id = '7xxdahuqmca5a'
),
object_list as (
    select '"'||t.owner||'"."'|| t.table_name||'"' full_object_name from dba_tables t, source s where s.object_owner = t.owner and s.object_name = t.table_name and s.object_type = 'TABLE'
    union
    select '"'||i.owner||'"."'|| i.table_name||'"' from dba_indexes i, source s where s.object_owner = i.owner and s.object_name = i.index_name and s.object_type = 'INDEX'
)

select 
    o.operation,
    case when o.notes <> lag(o.notes)over(partition by o.target order by o.start_time) then 'NOTES UPDATED' end op_note_changed,
    case when ot.notes <> lag(ot.notes)over(partition by ot.target order by ot.start_time) then 'NOTES UPDATED' end task_note_changed,
    (select 'Y' from dba_tab_stat_prefs pr 
        where owner = regexp_replace(ot.target,'"(\S+)"\."(\S+)"','\1') and table_name = regexp_replace(ot.target,'"(\S+)"\."(\S+)"','\2') and rownum = 1) has_prefs,
    ot.*,
    o.notes
from dba_optstat_operation_tasks ot,
    dba_optstat_operations o
where ot.opid = o.id(+)
    and ot.target in (select full_object_name from object_list) order by ot.target, ot.start_time desc;
    
    
    
    
    
    
    
create or replace package subprogram_utils is
    /**
     *
     */
    
    function get_current_subprogram (p_dynamic_depth in pls_integer) return varchar2
    is
        l_subprogram_owner varchar2(128);
        l_subprogram_name  varchar2(256);
    begin
        l_subprogram_owner := utl_call_stack.owner(dynamic_depth => p_dynamic_depth);
        l_subprogram_name  := utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram (dynamic_depth => p_dynamic_depth));
        
        return l_subprogram_owner || '.' || l_subprogram_name;
    end get_current_subprogram;
    
end subprogram_utils;
/





-- профилирование (profiler: dbms_hprof)

set timing on 
set serveroutput on size unl
declare
--  pragma autonomous_transaction; 
    l_ret number;
    p_errmsg varchar2(4000);
    p_date date := date'2023-09-10';
    p_cess number := 213;
    p_no number := null;
begin
    dbms_hprof.start_profiling (location => 'PROFILER_DIR', filename => 'dbykov_twr_436.trc');

    l_ret := ubrr_cess_vuz_report.reestr_daily_2021(p_errmsg,p_date,p_cess,p_no);
    
    dbms_hprof.stop_profiling;
end;
/


with function plshprof(p_filename in varchar2) return clob
    is
        c_location constant varchar2(16) := 'PROFILER_DIR';
        l_clob     clob;
    begin
        dbms_hprof.analyze(location    => c_location,
                           filename    => p_filename,
                           report_clob => l_clob);
        
        return l_clob;
    end;
source as (
    select 'hprof_rtwr_1546451816_207.trc' filename from dual
)
select 
    substr(s.filename, 1, instr(s.filename, '.', -1)) || 'html' file#,
    plshprof(p_filename => s.filename) output 
from source s;









--1. Какие сессии заблокированы
SELECT sid, serial#, username, osuser, machine, program, SQL_ID
  FROM v$session
 WHERE sid IN (SELECT DISTINCT sid FROM v$lock WHERE request > 0);

--2. Определение максимальной длины цепочки текущей блокировки
SELECT NVL (MAX (ct), 0) maxct
  FROM v$session VS,
       (  SELECT BLOCKER_PID,
                 BLOCKER_SID,
                 BLOCKER_SESS_SERIAL#,
                 COUNT (*) ct
            FROM v$wait_chains
           WHERE BLOCKER_IS_VALID = 'TRUE'
        GROUP BY BLOCKER_PID, BLOCKER_SID, BLOCKER_SESS_SERIAL#) LL
 WHERE     VS.SID = LL.BLOCKER_SID
       AND VS.SERIAL# = LL.BLOCKER_SESS_SERIAL#
       AND VS.TYPE = 'USER'

--3. Топ цепочек блокировки
--Посмотреть корни цепочек, самые длинные топ-10
SELECT CT,SID,SERIAL#,OSUSER,MACHINE,TERMINAL,SQL_ID,MODULE,ACTION,EVENT
  FROM (  SELECT LL.CT,
                 VS.SID,
                 VS.SERIAL#,
                 VS.OSUSER,
                 VS.MACHINE,
                 VS.TERMINAL,
                 VS.SQL_ID,
                 vs.module,
                 vs.ACTION,
                 vs.event,
                 ROWNUM rw
            FROM v$session VS,
                 (  SELECT BLOCKER_PID,
                           BLOCKER_SID,
                           BLOCKER_SESS_SERIAL#,
                           COUNT (*) ct
                      FROM v$wait_chains
                     WHERE BLOCKER_IS_VALID = 'TRUE'
                  GROUP BY BLOCKER_PID, BLOCKER_SID, BLOCKER_SESS_SERIAL#) LL
           WHERE     VS.SID = LL.BLOCKER_SID
                 AND VS.SERIAL# = LL.BLOCKER_SESS_SERIAL#
                 AND VS.TYPE = 'USER'
        ORDER BY CT DESC)
 WHERE rw < 11;
 
 
 
 
 
 -- SQL_ID generate test case
 
 with source as (
    select '1vfqf2sv20sns' sql_id from dual
),
sqltext as (
    select 
        sql_id, sql_text, chr(13) || chr(10) crlf, 'query' || to_char(sysdate, 'yyyymmddhh24miss') label
    from dba_hist_sqltext join source using (sql_id)
),
sqlbind as (
    select distinct
        b.bind_name, b.bind_type, b.var_name, b.position, bc.value_string bind_val
    from v$sql_bind_capture bc join source using (sql_id)
        right join (
            select
                name bind_name, replace(lower(name), ':', 'l_') var_name, datatype_string bind_type, min(position) position
            from dba_hist_sql_bind_metadata join source using (sql_id)
            group by name, datatype_string) b on b.bind_name = bc.name
    order by last_captured desc
    fetch first row with ties
)

select    
    'begin' || crlf ||
    q'[    execute immediate q'`explain plan set statement_id = 'dbykov' for ]' || crlf ||
    '        ' || sql_text || q'[`';]' || crlf ||
    'end;' || crlf || 
    '/' || crlf ||
    'select * from table(dbms_xplan.display);' || crlf output
from sqltext
union all
select
    to_clob(q'[select hint
from plan_table pt, 
    xmltable('/other_xml/outline_data/hint/text()' passing xmltype(pt.other_xml) columns hint varchar2(255) path '.')xt 
where pt.plan_id = (select max(plan_id) from plan_table where statement_id = 'dbykov') 
    and pt.id = 1 /*other_xml is not null*/;]') || crlf
from sqltext
union all
select
    'set timing on' || crlf  ||
    'set serveroutput on size unl' || crlf ||
    'declare'  || crlf  ||
    '    -- ' || label || crlf ||
    (select listagg('    ' || var_name || ' ' || bind_type || ' := ' || 
        case when regexp_like(bind_type, '^VARCHAR2\(\d+\)$') then '''' || bind_val || '''' else bind_val end || 
    ';' || crlf)within group(order by position) from sqlbind) ||
    '    --' || crlf ||
    '    cursor cur is' || crlf ||
    '        ' || regexp_replace(sql_text, ':(B\d{1,2})', 'L_\1') || ';' || crlf ||
    '    --' || crlf ||
    '    type l_cur_list is table of cur%rowtype;' || crlf ||
    '    l_cur l_cur_list;' || crlf ||
    'begin' || crlf ||
    '    execute immediate ''alter session set statistics_level=ALL'';' || crlf || crlf ||    
    '    open cur;' || crlf ||
    '        fetch cur bulk collect into l_cur;' || crlf ||
    '    close cur;' || crlf || crlf ||    
    '    dbms_output.put_line(l_cur.count);' || crlf || crlf ||    
    '    execute immediate ''alter session set statistics_level=' || 
        (select value from v$parameter where name = 'statistics_level') || ''';' || crlf ||  
    'end;' || crlf || 
    '/' || crlf
from sqltext
union all
select 
    'with source as (' || crlf ||
    '    select ''' || to_clob(label) || ''' label from dual' ||  crlf ||
    '),' || crlf || 
    'prnt_cur as (' || crlf ||
    '    select' || crlf ||
    '        sql_id' || crlf || 
    '    from source, v$sql' || crlf ||
    '    where sql_fulltext like ''%'' || label || ''%''' || crlf ||  
    '        and command_type = 47 /*PL/SQL BLOCK*/' || crlf ||
    '    order by last_load_time desc fetch first row only' || crlf ||
    '),' || crlf ||
    'chld_cur as (' || crlf ||
    '    select' || crlf ||
    '        ash.sql_id, ash.sql_child_number, s.sql_fulltext' || crlf ||
    '    from prnt_cur p' || crlf ||
    '        join v$active_session_history ash on ash.top_level_sql_id = p.sql_id' || crlf ||
    '        join v$sql s on s.sql_id = ash.sql_id and s.plan_hash_value = ash.sql_plan_hash_value and s.child_number = ash.sql_child_number' || crlf ||
    '    where ash.sql_opcode = 3 /*SELECT*/' || crlf ||
    '        and rownum = 1' || crlf ||
    ')' || crlf ||
    '--select * from chld_cur;' || crlf ||
    'select plan_table_output from chld_cur c,' || crlf ||
    '    table(dbms_xplan.display_cursor(sql_id          => c.sql_id,' || crlf ||
    '                                    cursor_child_no => c.sql_child_number,' || crlf ||
    '                                    format          => ''allstats last''));' || crlf
from sqltext;

select sql_id, address, hash_value ,
    'exec SYS.DBMS_SHARED_POOL.PURGE(''' || address || ',' || hash_value || ''', ''C'');' x
from v$sqlarea where sql_id = '1sxxfjt9jpgjw';









-- top cpu usage
select sql_id, count(distinct plan_hash_value) unq_phv, count(distinct trunc(sn.begin_interval_time)) unq_days, sum(st.executions_delta) e,
    round(sum(elapsed_time_delta)/1e6,2) ela , round(sum(cpu_time_delta)/1e6,2) cpu, round(sum(iowait_delta)/1e6,2) io, 
    round(sum(ccwait_delta)/1e6, 2) cc, round(sum(plsexec_time_delta)/1e6, 2) plsql, round(sum(javexec_time_delta)/1e6, 2) java,
    round(sum(cpu_time_delta)/greatest(sum(st.executions_delta),1)/1e6/2) avg_cpu#
from dba_hist_sqlstat st 
    join dba_hist_snapshot sn using(snap_id) 
    join dba_hist_sqltext sql using(sql_id)
    join dba_hist_sqlcommand_name cn using(command_type)
where cn.command_name = 'SELECT'
--    and sn.begin_interval_time between date'2023-12-13' and date'2023-12-14'
group by sql_id
--order by cpu/greatest(e,1) desc
order by cpu desc nulls last fetch first 10 row only