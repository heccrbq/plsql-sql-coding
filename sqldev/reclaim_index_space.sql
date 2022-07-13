/**
 * =============================================================================================
 * Ниже описано 6 подходов к оценке занимаемого идексом места.
 * Это необходимо для того, чтобы понимать распух ли индекс и стоит ли сделать его rebuld / shrink
 * =============================================================================================
 *  - estimated used index size based on index & table statistics
 *  - SPACE_USAGE & UNUSED_SPACE
 *  - segment advisor
 *  - CREATE_INDEX_COST 
 *  - explain plan
 *  - validate structure
 * =============================================================================================
 * @param   index_owner (VARCHAR2)   Схема владельца индекса
 * @param   index_name  (VARCHAR2)   Наименование индекса
 * =============================================================================================
 */
 
 
 -- #1. estimated used index size based on index & table statistics
 with source as (
    select 'A4M' index_owner, 'PK_RETADJUSTTRAN' index_name from dual
)

select 
    i.owner index_owner, 
    i.index_name, 
--    i.table_owner, 
--    i.table_name, 
    i.partitioned,
    i.num_rows, 
    i.distinct_keys,
    ca.avg_row_len, 
    i.blevel, 
    i.leaf_blocks, 
--    i.avg_leaf_blocks_per_key,
--    i.avg_data_blocks_per_key,    
    round(s.bytes/1024/1024, 3) allocated_for_segment_mb,
    round(i.num_rows * ca.avg_row_len / 1024 / 1024, 3) used_by_data_mb,
    -- 12 = 10 bytes for rowid + 2 bytes for the index row header
    round((i.num_rows * 12 + ca.avg_rowset_len * (1 + i.pct_free/100))/ 1024 / 1024, 3) estimated_index_size_mb,
    round((i.num_rows * 12 + ca.avg_rowset_len * (1 + i.pct_free/100)) / s.bytes * 100, 2) pct_used
from dba_indexes i
    join dba_segments s on s.owner = i.owner and s.segment_name = i.index_name
    outer apply (
        select 
            sum(tcs.avg_col_len) avg_row_len,
            sum((ins.num_rows - tcs.num_nulls) * tcs.avg_col_len) avg_rowset_len            
        from dba_tables t 
            join dba_tab_col_statistics tcs on tcs.owner = t.owner and tcs.table_name = t.table_name
            join dba_ind_columns ic on ic.index_owner = i.owner and ic.index_name = i.index_name and tcs.column_name = ic.column_name
            join dba_ind_statistics ins on ins.owner = ic.index_owner and ins.index_name = ic.index_name
        where t.table_name = i.table_name and t.owner = i.table_owner
    ) ca
where (i.owner, i.index_name) in (select * from source);
