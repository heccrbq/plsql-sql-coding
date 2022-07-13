/**
 * =============================================================================================
 * Ниже описано 6 подходов к оценке занимаемого идексом места.
 * Это необходимо для того, чтобы понимать распух ли индекс и стоит ли сделать его rebuld / shrink
 * =============================================================================================
 *  - estimated used index size based on index & table statistics
 *  - SPACE_USAGE & UNUSED_SPACE
 *  - CREATE_INDEX_COST
 *  - explain plan
 *  - segment advisor
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


-- #2. SPACE_USAGE & UNUSED_SPACE
set serveroutput on size unl
declare
    l_segment_owner  varchar2(30) := 'A4M';
    l_segment_name   varchar2(30) := 'PK_RETADJUSTTRAN';
    l_segment_type   varchar2(30) := 'INDEX';
    -- space_usage
    l_unformatted_blocks number;
    l_unformatted_bytes  number;
    l_fs1_blocks         number;
    l_fs1_bytes          number;
    l_fs2_blocks         number;
    l_fs2_bytes          number;
    l_fs3_blocks         number;
    l_fs3_bytes          number;
    l_fs4_blocks         number;
    l_fs4_bytes          number;
    l_full_blocks        number;
    l_full_bytes         number;
    -- unused_space
    l_total_blocks              number;
    l_total_bytes               number;
    l_unused_blocks             number;
    l_unused_bytes              number;
    l_last_used_extent_file_id  number;
    l_last_used_extent_block_id number;
    l_last_used_block           number;
begin
    dbms_space.space_usage (segment_owner       => l_segment_owner, 
                            segment_name        => l_segment_name,
                            segment_type        => l_segment_type,
                            unformatted_blocks  => l_unformatted_blocks,
                            unformatted_bytes   => l_unformatted_bytes,
                            fs1_blocks          => l_fs1_blocks,
                            fs1_bytes           => l_fs1_bytes,
                            fs2_blocks          => l_fs2_blocks,
                            fs2_bytes           => l_fs2_bytes,
                            fs3_blocks          => l_fs3_blocks,
                            fs3_bytes           => l_fs3_bytes,
                            fs4_blocks          => l_fs4_blocks,
                            fs4_bytes           => l_fs4_bytes,
                            full_blocks         => l_full_blocks,
                            full_bytes          => l_full_bytes,
                            partition_name      => null);
  
    dbms_output.put_line('DBMS_SPACE.SPACE_USAGE' || chr(10) || lpad('-', 25, '-'));
    dbms_output.put_line('Total number of blocks unformatted                     : ' || l_unformatted_blocks);
    dbms_output.put_line('Total number of bytes unformatted                      : ' || l_unformatted_bytes);                         
    dbms_output.put_line('Number of blocks having at least  0 to  25% free space : ' || l_fs1_blocks);
    dbms_output.put_line('Number of bytes  having at least  0 to  25% free space : ' || l_fs1_bytes);
    dbms_output.put_line('Number of blocks having at least 25 to  50% free space : ' || l_fs2_blocks);
    dbms_output.put_line('Number of bytes  having at least 25 to  50% free space : ' || l_fs2_bytes);
    dbms_output.put_line('Number of blocks having at least 50 to  75% free space : ' || l_fs3_blocks);
    dbms_output.put_line('Number of bytes  having at least 50 to  75% free space : ' || l_fs3_bytes);
    dbms_output.put_line('Number of blocks having at least 75 to 100% free space : ' || l_fs4_blocks);
    dbms_output.put_line('Number of bytes  having at least 75 to 100% free space : ' || l_fs4_bytes);
    dbms_output.put_line('Total number of blocks full in the segment             : ' || l_full_blocks);
    dbms_output.put_line('Total number of bytes full in the segment              : ' || l_full_bytes);
    
    dbms_output.put_line(null);
    
    dbms_space.unused_space (segment_owner              => l_segment_owner, 
                             segment_name               => l_segment_name,
                             segment_type               => l_segment_type,
                             total_blocks               => l_total_blocks,
                             total_bytes                => l_total_bytes,
                             unused_blocks              => l_unused_blocks,
                             unused_bytes               => l_unused_bytes,
                             last_used_extent_file_id   => l_last_used_extent_file_id,
                             last_used_extent_block_id  => l_last_used_extent_block_id,
                             last_used_block            => l_last_used_block,
                             partition_name             => null);

    dbms_output.put_line('DBMS_SPACE.UNUSED_SPACE' || chr(10) || lpad('-', 25, '-'));
    dbms_output.put_line('Total number of blocks in the segment                        : ' || l_total_blocks);
    dbms_output.put_line('Total number of blocks in the segment, in bytes              : ' || l_total_bytes);
    dbms_output.put_line('Number of blocks which are not used                          : ' || l_unused_blocks);
    dbms_output.put_line('Number of blocks which are not used, in bytes                : ' || l_unused_bytes);
    dbms_output.put_line('The file ID of the last extent which contains data           : ' || l_last_used_extent_file_id);
    dbms_output.put_line('The starting block ID of the last extent which contains data : ' || l_last_used_extent_block_id);
    dbms_output.put_line('The last block within this extent which contains data        : ' || l_last_used_block);
end;
/


-- #3. CREATE_INDEX_COST
set serveroutput on size unl
declare 
    l_segment_owner varchar2(30) := 'A4M';
    l_segment_name  varchar2(30) := 'PK_RETADJUSTTRAN';
    l_segment_type  varchar2(30) := 'INDEX';
    --
    l_index_ddl       clob;
    l_used_bytes      number; 
    l_allocated_bytes number; 
begin 
    l_index_ddl := dbms_metadata.get_ddl(l_segment_type, l_segment_name, l_segment_owner); 
    
    dbms_space.create_index_cost (ddl             => l_index_ddl,
                                  used_bytes      => l_used_bytes,
                                  alloc_bytes     => l_allocated_bytes);
                                  
    dbms_output.put_line('Used,      MBytes: ' || round(l_used_bytes/1024/1024)); 
    dbms_output.put_line('Allocated, MBytes: ' || round(l_allocated_bytes/1024/1024)); 
end; 
/
