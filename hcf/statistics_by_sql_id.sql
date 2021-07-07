whenever sqlerror exit rollback
set timing on			-- выводить время выполнения
set verify off			-- не выводить old запрос при использовании define
set feedback on 		-- выводить n rows selected
set pagesize 500		-- выводить по 50 строк на одной странице
--
def table_owner = "'A4M'"
def table_name  = "'TENTRY'"
def sql_id = "'4a2qd5ukugzzm'"

TTITLE LEFT ===================================== SKIP 1 -
       LEFT 'T A B L E   S T A T I S T I C S :'   SKIP 1-
       LEFT ===================================== SKIP 1 
/
--col sample_size      head 'SAMPLE, %'
--col temporary        head 'TEMP'
--col compress_for     head 'COMPRESS'
--
col owner            for a10
col table_name       for a30
col iot_name         for a10
col part_key_columns for a20
col temporary        for a5              heading 'TEMP'
col compress_for     for a10             heading 'COMPRESS'
col allocated_blocks for 999G999G999G999
col gbytes           for 999G999G999G999
col blocks           for 999G999G999G999
col num_rows         for 999G999G999G999
col sample_size      for a10             heading 'SAMPLE, %'
col last_analyzed    for a20
col global_stats     for a15
col user_stats       for a15
--
select
    t.owner
    ,t.table_name
    ,t.iot_name
    ,t.partitioned
    ,(select listagg(pkc.column_name, ', ')within group(order by pkc.column_position) from dba_part_key_columns pkc where pkc.owner = t.owner and pkc.name = t.table_name) part_key_columns 
    ,t.temporary
    ,t.compress_for
    ,t.pct_free
    ,t.pct_used
    ,t.status
    ,seg.gbytes
--    ,seg.blocks allocated_blocks
    ,t.num_rows
    ,t.blocks
    ,t.empty_blocks
    ,t.avg_row_len
    ,t.last_analyzed
    ,round(t.sample_size / decode(t.num_rows,0,1,t.num_rows) * 100) sample_size
    ,t.global_stats
    ,t.user_stats
from dba_tables t,
    lateral
        (select
            round(sum(seg.bytes)/1024/1024, 2) gbytes,
            sum(seg.blocks) blocks
        from dba_segments seg
        where seg.owner = t.owner
            and seg.segment_name = t.table_name
        ) seg
where t.owner = &table_owner /*p_table_owner*/
  and t.table_name = &table_name/*p_table_name*/;


TTITLE LEFT ===================================== SKIP 1 -
       LEFT 'I N D E X   S T A T I S T I C S :'   SKIP 1 -
       LEFT ===================================== SKIP 1 
/
--col sample_size       head 'SAMPLE, %'
--col index_type        head 'TYPE'
--
col owner             for a10
col table_name        for a30
col index_name        for a30
col column_list       for a50
col index_type        for a10
col partitioned       for a12
col part_key_columns  for a20
col gbytes            for 999G999G999G999
col blocks            for 999G999G999G999
col num_rows          for 999G999G999G999
col distinct_keys     for 999G999G999G999
col leaf_blocks       for 999G999G999G999
col clustering_factor for 999G999G999G999
col last_analyzed     for a20
col sample_size       for a10             heading 'SAMPLE, %'
col global_stats      for a15
col user_stats        for a15
col locality          for a10
--
select 
    ix.owner
    ,ix.table_name
    ,ix.index_name
    ,(select
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
    from dba_ind_columns ic where ix.owner = ic.index_owner and ix.index_name = ic.index_name) column_list
    ,decode(ix.index_type, 'NORMAL', 'B-TREE', 'FUNCTION-BASED NORMAL', 'FBI', ix.index_type) index_type
    ,ix.uniqueness
    ,ix.partitioned
    ,pi.locality
    ,(select listagg(pkc.column_name, ', ')within group(order by pkc.column_position) from dba_part_key_columns pkc where pkc.owner = ix.owner and pkc.name = ix.index_name) part_key_columns
    ,ix.status
    ,seg.gbytes
    ,seg.blocks
    ,ix.num_rows
    ,ix.distinct_keys
    ,ix.blevel
    ,ix.leaf_blocks
    ,ix.clustering_factor
    ,ix.last_analyzed
    ,round(ix.sample_size / decode(ix.num_rows,0,1,ix.num_rows) * 100) sample_size
    ,ix.global_stats
    ,ix.user_stats
from dba_indexes ix,
    dba_part_indexes pi,
    lateral
        (select
            round(sum(seg.bytes)/1024/1024, 2) gbytes,
            sum(seg.blocks) blocks
        from dba_segments seg
        where seg.owner = ix.owner
            and seg.segment_name = ix.index_name
        ) seg
where ix.owner = &table_owner /*p_table_owner*/
    and ix.table_name = &table_name /*p_table_name*/
    and pi.owner(+) = ix.owner and pi.index_name(+) = ix.index_name
order by ix.table_name,
    ix.index_name;
    
    
TTITLE LEFT ===================================== SKIP 1 -
       LEFT 'Q U E R Y   S T A T I S T I C S :'   SKIP 1 -
       LEFT ===================================== SKIP 1 
/
select 
    s.sql_id, s.plan_hash_value, s.child_number, 
	s.loaded_versions, s.first_load_time, s.invalidations, s.is_reoptimizable,
    round(s.elapsed_time / 1e6, 4) elapsed_time_sec,
	round(s.cpu_time / 1e6, 4) cpu_time_sec, 
	round(ss.avg_hard_parse_time / 1e6, 4) avg_hard_parse_time_sec, 
	round(s.concurrency_wait_time / 1e6, 4) concurrency_wait_time_sec, 
	round(s.user_io_wait_time / 1e6, 4) user_io_wait_time_sec, s.application_wait_time,
    s.disk_reads, s.buffer_gets, s.direct_writes, s.direct_reads, 
    s.rows_processed, s.fetches, s.end_of_fetch_count,
    s.executions, s.parse_calls, s.px_servers_executions, 
    s.program_id, s.program_line# 
from v$sql s,
    v$sqlstats ss
where s.sql_id = &sql_id/*:sql_id*/
--	and s.plan_hash_value = 3682407720/*:sql_plan_hash_value*/
--	and s.child_number = 3/*:sql_child_number*/
    and s.sql_id = ss.sql_id(+)
    and s.plan_hash_value = ss.plan_hash_value(+);
    
    
col event      for a30
col wait_class for a20
select 
    session_state, 
    event, 
    wait_class, 
    count(1) wait_count, 
    round(sum(time_waited)/1e3, 2) time_waited,
    round((ratio_to_report(count(1)) over ())*100, 2) as percent
from gv$active_session_history
where sql_id = &sql_id/*:sql_id*/
--	and sql_plan_hash_value = 3682407720/*:sql_plan_hash_value*/
--	and sql_child_number = 3 /*:sql_child_number*/
group by session_state, event, wait_class, sql_plan_hash_value, sql_child_number
order by wait_count desc;
