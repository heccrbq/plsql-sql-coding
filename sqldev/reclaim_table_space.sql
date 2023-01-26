-- #1. estimated used table size based on table statistics
with source as (
    select 'A4M' table_owner, 'TDOCUMENT' table_name from dual
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

-- #4. segment advisor
--   exec dbms_advisor.delete_task('heccrbq_advisor_taks');

declare
    l_segment_owner varchar2(30) := 'A4M';
    l_segment_name  varchar2(30) := 'TDOCUMENT';
    l_segment_type  varchar2(30) := 'TABLE';
    --
    l_obj_id   number;
    l_task_name varchar2(30) := 'heccrbq_advisor_taks';
begin
      dbms_advisor.create_task (
        advisor_name     => 'Segment Advisor', -- dba_advisor_definitions.advisor_name
        task_name        => l_task_name);
  
     dbms_advisor.create_object (
       task_name        => l_task_name,
       object_type      => l_segment_type,
       attr1            => l_segment_owner,
       attr2            => l_segment_name,
       attr3            => NULL,
       attr4            => NULL,
       attr5            => NULL,
       object_id        => l_obj_id);
 
     dbms_advisor.set_task_parameter(
       task_name        => l_task_name,
       parameter        => 'recommend_all',
       value            => 'TRUE');
 
     dbms_advisor.execute_task(l_task_name);
   end;
/

 with source as (
    select 'A4M' index_owner, 'TDOCUMENT' index_name from dual
)
select 
    segment_owner,
    segment_name,
    round(allocated_space/1024/1024,1) alloc_mb,
    round( used_space/1024/1024, 1 ) used_mb,
    round( reclaimable_space/1024/1024) reclaim_mb,
    round(reclaimable_space/allocated_space*100,0) pctsave,
    recommendations,
    c1,
    c2,
    c3
  from table(dbms_space.asa_recommendations()) r
where (r.segment_owner, r.segment_name) in (select * from source);
