alter session set statistics_level=basic; -- TYPICAL
select * from v$statname where name like '%recur%';

select statistic#, display_name, value from v$mystat ms join v$statname sn using (statistic#)
where sn.name in ('sorts (memory)','sorts (disk)','sorts (rows)', 'recursive calls','recursive cpu usage',
'physical reads direct temporary tablespace', 'physical writes direct temporary tablespace', 'temp space allocated (bytes)');
select 40673 - 41145, 
41550 - 41899, 42237 - 42664 from dual;

drop table dropme purge;
create table dropme as select /*+no_gather_optimizer_statistics*/ * from grant_aud;

col table_name for a12
select table_name, last_analyzed, num_rows, blocks from user_tables where table_name = 'DROPME';

sho parameter stat;

STATISTIC# DISPLAY_NAME                                                          VALUE     VALUE2      DIFF
---------- ---------------------------------------------------------------- ---------- ---------- ---------
       164 physical reads direct temporary tablespace                                3          3         0
       165 physical writes direct temporary tablespace                               1          1         0
       548 temp space allocated (bytes)                                        4194304    4194304         0
      1717 sorts (memory)                                                         1764       1765         1
      1718 sorts (disk)                                                              0          0         0
      1719 sorts (rows)                                                         148846     283950    135104
      
      
STATISTIC# DISPLAY_NAME                                                          VALUE     VALUE2      DIFF
---------- ---------------------------------------------------------------- ---------- ---------- ---------
       164 physical reads direct temporary tablespace                                3          3         0
       165 physical writes direct temporary tablespace                               1          1         0
       548 temp space allocated (bytes)                                        4194304    4194304         0
      1717 sorts (memory)                                                         1773       1774         1
      1718 sorts (disk)                                                              0          0         0
      1719 sorts (rows)                                                         284143     419247    135104
      
      
/
select 692110 - 556982 from dual;

TABLE_NAME   LAST_ANALYZED         NUM_ROWS     BLOCKS
------------ ------------------- ---------- ----------
DROPME       03.08.2022 16:13:17    6877115      33631


TABLE_NAME   LAST_ANALYZED         NUM_ROWS     BLOCKS
------------ ------------------- ---------- ----------
DROPME 
      
      select * from v$sql where sql_id in ('9k0su4j5r9kut','08ag24f90kn3a');
      
      select * from table(dbms_xplan.display_cursor(sql_id => '9k0su4j5r9kut', format => 'basic +hint_report'));
      
      