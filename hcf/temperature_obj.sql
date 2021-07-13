with check_sql as (
    select /*+ materialize */
        sql_id
    from gv$sql
    where hash_value in (select from_hash from gv$object_dependency where to_name = 'HCF_REPORTING')
)

select 
    to_char(sn.end_interval_time, 'yyyy/mm/dd hh24:mi') snap_time,
    sum(s.executions_delta) exec_cnt,
    round(sum(s.executions_delta / (cast(sn.end_interval_time as date) - cast(sn.begin_interval_time as date))/24/60)) exec_cnt_per_minute
from dba_hist_sqlstat s,
    dba_hist_snapshot sn
where s.sql_id in (select /*+ no_unnest */ sql_id from check_sql)
    and s.snap_id = sn.snap_id
    and s.dbid = sn.dbid
    and s.instance_number = sn.instance_number
    and sn.end_interval_time between sysdate-1 and sysdate
group by to_char(sn.end_interval_time, 'yyyy/mm/dd hh24:mi')
order by 1 desc;
