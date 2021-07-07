with sql_plan_data as (
        select id, parent_id, plan_hash_value
        from   dba_hist_sql_plan
        where  sql_id = '3cks5v1jgxctx'
        and    plan_hash_value = nvl('2717491632', plan_hash_value)
--        and    dbid = &v_xa_dbid
        )
,    hierarchy_data as (
        select  id, parent_id, plan_hash_value
        from    sql_plan_data
        start   with id = 0
        connect by prior id = parent_id
               and prior plan_hash_value = plan_hash_value 
        order   siblings by id desc
        )
,    ordered_hierarchy_data as (
        select id
        ,      parent_id as pid
        ,      plan_hash_value as phv
        ,      row_number() over (partition by plan_hash_value order by rownum desc) as oid
        ,      max(id) over (partition by plan_hash_value) as maxid
        from   hierarchy_data
        )
,    xplan_data as (
        select /*+ ordered use_nl(o) */
               rownum as r
        ,      x.plan_table_output as plan_table_output
        ,      o.id
        ,      o.pid
        ,      o.oid
        ,      o.maxid
        ,      p.phv
        ,      count(*) over () as rc
        from  (
               select distinct phv
               from   ordered_hierarchy_data
              ) p
               cross join
               table(dbms_xplan.display_awr('3cks5v1jgxctx',p.phv,null,'ALL')) x
               left outer join
               ordered_hierarchy_data o
               on (    o.phv = p.phv
                   and o.id = case
                                 when regexp_like(x.plan_table_output, '^\|[\* 0-9]+\|')
                                 then to_number(regexp_substr(x.plan_table_output, '[0-9]+'))
                              end)
        )
select plan_table_output
from   xplan_data
model
   dimension by (phv, rownum as r)
   measures (plan_table_output,
             id,
             maxid,
             pid,
             oid,
             greatest(max(length(maxid)) over () + 3, 6) as csize,
             cast(null as varchar2(128)) as inject,
             rc)
   rules sequential order (
          inject[phv,r] = case
                             when id[cv(),cv()+1] = 0
                             or   id[cv(),cv()+3] = 0
                             or   id[cv(),cv()-1] = maxid[cv(),cv()-1]
                             then rpad('-', csize[cv(),cv()]*2, '-')
                             when id[cv(),cv()+2] = 0
                             then '|' || lpad('Pid |', csize[cv(),cv()]) || lpad('Ord |', csize[cv(),cv()])
                             when id[cv(),cv()] is not null
                             then '|' || lpad(pid[cv(),cv()] || ' |', csize[cv(),cv()]) || lpad(oid[cv(),cv()] || ' |', csize[cv(),cv()]) 
                          end, 
          plan_table_output[phv,r] = case
                                        when inject[cv(),cv()] like '---%'
                                        then inject[cv(),cv()] || plan_table_output[cv(),cv()]
                                        when inject[cv(),cv()] is not null
                                        then regexp_replace(plan_table_output[cv(),cv()], '\|', inject[cv(),cv()], 1, 2)
                                        else plan_table_output[cv(),cv()]
                                     end
         )
order  by r;















with sql_plan_data as (
        select  id, parent_id
        from    gv$sql_plan
        where   inst_id = sys_context('userenv','instance')
        and     sql_id = '1t7xxb8guh5cp'
--        and     child_number = 0
        )
,    hierarchy_data as (
        select  id, parent_id
        from    sql_plan_data
        start   with id = 0
        connect by prior id = parent_id
        order   siblings by id desc
        )
,    ordered_hierarchy_data as (
        select id
        ,      parent_id as pid
        ,      row_number() over (order by rownum desc) as oid
        ,      max(id) over () as maxid
        from   hierarchy_data
        )
,    xplan_data as (
        select /*+ ordered use_nl(o) */
               rownum as r
        ,      x.plan_table_output as plan_table_output
        ,      o.id
        ,      o.pid
        ,      o.oid
        ,      o.maxid 
        ,      count(*) over () as rc
        from   table(dbms_xplan.display_cursor('1t7xxb8guh5cp',0,'ALLSTATS LAST')) x
               left outer join
               ordered_hierarchy_data o
               on (o.id = case
                             when regexp_like(x.plan_table_output, '^\|[\* 0-9]+\|')
                             then to_number(regexp_substr(x.plan_table_output, '[0-9]+'))
                          end)
        )
select plan_table_output
from   xplan_data
model
   dimension by (rownum as r)
   measures (plan_table_output,
             id,
             maxid,
             pid,
             oid,
             greatest(max(length(maxid)) over () + 3, 6) as csize,
             cast(null as varchar2(128)) as inject,
             rc)
   rules sequential order (
          inject[r] = case
                         when id[cv()+1] = 0   or   id[cv()+3] = 0   or   id[cv()-1] = maxid[cv()-1]
                         then rpad('-', csize[cv()]*2, '-')
                         when id[cv()+2] = 0
                         then '|' || lpad('Pid |', csize[cv()]) || lpad('Ord |', csize[cv()])
                         when id[cv()] is not null
                         then '|' || lpad(pid[cv()] || ' |', csize[cv()]) || lpad(oid[cv()] || ' |', csize[cv()]) 
                      end, 
          plan_table_output[r] = case
                                    when inject[cv()] like '---%'
                                    then inject[cv()] || plan_table_output[cv()]
                                    when inject[cv()] is not null
                                    then regexp_replace(plan_table_output[cv()], '\|', inject[cv()], 1, 2)
                                    else plan_table_output[cv()]
                                 end
         )
order  by r;
