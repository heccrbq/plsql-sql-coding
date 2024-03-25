select 
    d.name db_name, d.dbid db_id, d.db_unique_name unique_name, d.database_role role, p.value rac,
    d.cdb 
from gv$database d,
    gv$parameter p
where p.name = 'cluster_database';

select instance_name instance, instance_number inst_num, startup_time from gv$instance;

select 
    min(snap_id), max(snap_id), 
    to_char(min(begin_interval_time)keep(dense_rank first order by snap_id), 'dd-Mon-yy hh24:mi:ss') snap_time,
    to_char(max(begin_interval_time)keep(dense_rank first order by snap_id), 'dd-Mon-yy hh24:mi:ss') snap_time2
from dba_hist_snapshot where snap_id between 102743 and 102744





 