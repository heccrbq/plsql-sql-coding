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
from dual
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
