-- Сформировать sql plan по dba_hist
select 
    plan_hash_value,
    id,
    lpad(' ', depth) || operation operation,
    options,
    object_owner,
    object_name,
    p.object_type,
    optimizer,
    cost,
    p.cardinality,
    p.bytes,
    p.cpu_cost,
    p.io_cost,
    access_predicates,
    filter_predicates,
    p.parent_id
from dba_hist_sql_plan p
where sql_id = '3srshtyjrcghw'
order by plan_hash_value, id
