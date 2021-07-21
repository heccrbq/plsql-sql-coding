
**********************************************************************************************************************
************************************** E S T I M A T E D   I N D E X    S I Z E **************************************
**********************************************************************************************************************

Для того чтобы рассчитать примерный размер индекса необходимо иметь актуальную статистику по таблице и полям.
Сложить avg_col_len по всем полям входящим в индекс, но при этом стоит учитывать, что null значения не попадают в btree индекс.
Добавить к полученному значению длину rowid.
Также нужно учесть вероятный pctfree в 10%.
Add 2 bytes for the index row header to get the average row size.

Более полно раписано тут - http://www.dba-oracle.com/t_estimate_oracle_index_size.htm

select 
    -- 10 bytes for rowid + 2 bytes for the index row header / 0.9 - pctfree 10
    (t.num_rows*10 +     
    sum(tcs.avg_col_len * (t.num_rows - num_nulls))) / 1024 /1024 / 0.9
--    ,tcs.sample_size
from user_tables t 
    inner join user_tab_col_statistics tcs on tcs.table_name = t.table_name
where t.table_name = 'TATMEXT' and tcs.column_name in ('BRANCH','PAN','MBR')
group by t.num_rows;

**********************************************************************************************************************

used  - The number of bytes representing the actual index data.
alloc - Size of the index when created in the tablespace.

set serveroutput on
declare 
 ub number; 
 ab number; 
begin 
 dbms_space.create_index_cost (
    ddl             => 'CREATE UNIQUE INDEX iatmext ON tatmext(branch, docno) tablespace tbs_idx compress 1',
    used_bytes      => ub,
    alloc_bytes     => ab
   );
 dbms_output.put_line('Used MBytes: ' || round(ub/1024/1024)); 
 dbms_output.put_line('Alloc MBytes: ' || round(ab/1024/1024)); 
end; 
/

**********************************************************************************************************************

explain plan for
  create index i on t (r);

select * 
from   table(dbms_xplan.display(null, null, 'basic +note'));

PLAN_TABLE_OUTPUT                                                                                                                         
---------------------------------------
Plan hash value: 1744693673                                                                                                                 

---------------------------------------                                                                                                     
| Id  | Operation              | Name |                                                                                                     
---------------------------------------                                                                                                     
|   0 | CREATE INDEX STATEMENT |      |                                                                                                     
|   1 |  INDEX BUILD NON UNIQUE| I    |                                                                                                     
|   2 |   SORT CREATE INDEX    |      |                                                                                                     
|   3 |    TABLE ACCESS FULL   | T    |                                                                                                     
---------------------------------------                                                                                                     

Note                                                                                                                                        
-----                                                                                                                                       
   - estimated index size: 4194K bytes

**********************************************************************************************************************
