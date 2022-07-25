col group_name for a18
col object_name for a26
col last_analyzed for a22
col pct_sample for a11
col global_stats heading GL_STAT
col user_stats heading USR_STAT
with source as (
    select sys.odcivarchar2list('TREFERENCEENTRY' , 'TDOCUMENT', 'TENTRY') table_list from dual
)

select 
    table_name group_name, table_name object_name, object_type, last_analyzed, num_rows, blocks, sample_size, to_char(round(sample_size/num_rows * 100, 2), '999D99') || '%' pct_sample, global_stats, user_stats 
from dba_tab_statistics where table_name in (select /*+dynamic_sampling(3)*/ column_value from source s, table(s.table_list))
union all
select 
    table_name, index_name object_name, object_type, last_analyzed, num_rows, leaf_blocks, sample_size, to_char(round(sample_size/num_rows * 100, 2), '990D99') || '%' pct_sample, global_stats, user_stats 
from dba_ind_statistics where table_name in (select /*+dynamic_sampling(3)*/ column_value from source s, table(s.table_list))
order by group_name, object_type desc, object_name;



-- find information by last_analyzed
col operation for a30
col target for a30
col status for a11
with source as (
    select 'A4M' table_owner, 'TDOCUMENT' table_name from dual
),
opt as (
    select 
        st.id opid,
        st.operation,
        st.target,
        st.start_time,
        st.end_time,
        st.status,
        st.session_id
    from source s,
        dba_optstat_operations st,
        dba_tables t 
    where (t.owner, t.table_name) in (select table_owner, table_name from source)
        and t.last_analyzed between cast(st.start_time as date) and cast(st.end_time as date)
        and (t.owner || '.' || t.table_name = st.target 
            and st.operation in ('restore_table_stats', 'gather_table_stats') 
            or st.operation = 'gather_database_stats (auto)')
)

select * from opt
union all
select * from (
    select 
        oot.opid,
        ' - ' || lower(oot.target_type) operation,
        oot.target,
        oot.start_time,
        oot.end_time,
        oot.status,
        null
    from opt,
        dba_optstat_operation_tasks oot
    where opt.opid = oot.opid
    order by oot.priority
);


-- find information in real time
with source as (
    select 'A4M' table_owner, 'TENTRY' table_name from dual
)
select 
    st.id opid,
    st.operation,
    st.target,
    st.start_time,
    st.end_time,
    st.status,
    st.session_id
from source s,
    dba_optstat_operations st
where s.table_owner || '.' || table_name = st.target
union all
select * from (
    select
        oot.opid,
        ' - ' || lower(oot.target_type) operation,
        oot.target,
        oot.start_time,
        oot.end_time,
        oot.status,
        null
    from source s,
        dba_optstat_operations st,
        dba_optstat_operation_tasks oot
    where s.table_owner || '.' || table_name = st.target
        and oot.opid = st.id
    order by oot.priority
)
order by opid, start_time;



col name for a18 heading PARAMETER_NAME
with source as (
    select 18906253 opid from dual
)
select 
--    operation, target, 
    xt.* 
from dba_optstat_operations, 
    xmltable('/params/param' passing xmltype(notes) 
        columns name varchar2(30) path '@name', 
               value varchar2(30) path '@val') xt 
where id = (select opid from source);


with source as (
    select 18906253 opid from dual
)
select 
--    target_type, target, 
    xt.*
from dba_optstat_operation_tasks,
    xmltable('/notes' passing xmltype(notes) columns histogram_col_list varchar2(30) path 'histograms', 
                                                                 xstats varchar2(30) path 'xstats') xt 
where opid = (select opid from source)
    and notes is not null;
