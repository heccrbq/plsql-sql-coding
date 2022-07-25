drop table dbykov_test purge;
drop table dbykov_temp purge;
create table dbykov_test pctfree 10 as select * From dba_objects;
create table dbykov_temp pctfree 0 as select * From dbykov_test where 1=0;
create unique index IDX_DBYKOV_TEST_OBJECT_ID on dbykov_test(object_id);
select bytes/1024/1024 mbytes from dba_segments where segment_name = 'IDX_DBYKOV_TEST_OBJECT_ID';
select count(1) from dbykov_test; -- 491984

analyze index IDX_DBYKOV_TEST_OBJECT_ID validate structure;
select * from index_stats;
-- select (lf_rows_len + lf_blk_len + br_rows_len + del_lf_rows_len), used_space, btree_space, pct_used, HEIGHT + (ROWS_PER_KEY + 1)/2 calculated_blks_gets_per_access from index_stats;

truncate table dbykov_temp;
insert into dbykov_temp select * from dbykov_test where object_id <= 100;
update dbykov_temp set object_id = (select max(object_id) from dbykov_test) + rownum;
commit;

delete from dbykov_test where object_id <= 100;
commit;

analyze index IDX_DBYKOV_TEST_OBJECT_ID validate structure;
select * from index_stats;

insert into dbykov_test select * From dbykov_temp;
commit;

analyze index IDX_DBYKOV_TEST_OBJECT_ID validate structure;
select * from index_stats;

-- there is the difference between the distinct_keys column in dba_ind_statistics and index_stats
select * From dba_ind_statistics where index_name = 'IDX_DBYKOV_TEST_OBJECT_ID';
exec dbms_stats.gather_index_stats('A4M','IDX_DBYKOV_TEST_OBJECT_ID');


select * From all_tab_modifications where table_name = 'TDOCUMENT';

