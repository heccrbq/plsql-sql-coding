select 
    inst_id, db_unique_name, log_mode, 
    supplemental_log_data_min,
    supplemental_log_data_pk,
    supplemental_log_data_ui,
    supplemental_log_data_fk,
    supplemental_log_data_all,
    supplemental_log_data_pl
from gv$database;


select * From dba_log_groups;
select * From dba_log_group_columns; -- if USER LOG GROUP


drop table dbykov_test purge;
create table dbykov_test pctfree 0 as select 1 x, 2 y, 3 z From dual;

--Enabling Supplemental Logging at Table Level

ALTER TABLE dbykov_test ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE dbykov_test ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;
ALTER TABLE dbykov_test ADD SUPPLEMENTAL LOG DATA (UNIQUE) COLUMNS;
--ALTER TABLE dbykov_test ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY, UNIQUE) COLUMNS;
ALTER TABLE dbykov_test ADD SUPPLEMENTAL LOG GROUP lg_dbykov_test (x,y) ALWAYS;


--Disable the supplemental Logging at table level

ALTER TABLE dbykov_test DROP SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE dbykov_test DROP SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;
ALTER TABLE dbykov_test DROP SUPPLEMENTAL LOG DATA (UNIQUE) COLUMNS;
ALTER TABLE dbykov_test DROP SUPPLEMENTAL LOG GROUP lg_dbykov_test;
