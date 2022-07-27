-- if the mview_name column is null, then it is a fake subscriber
select 
    btm.owner, btm.master, ml.log_table, btm.mview_id, rm.name mview_name, rm. mview_site, btm.mview_last_refresh_time, rm.query_txt 
from dba_base_table_mviews btm  -- sys.slog$
    left join dba_registered_mviews rm on rm.mview_id = btm.mview_id
    left join dba_mview_logs ml on ml.log_owner = btm.owner and ml.master = btm.master;


