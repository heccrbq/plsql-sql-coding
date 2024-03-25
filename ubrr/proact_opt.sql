
-- запросы, где присутствует TABLE ACCESS FULL UBRR таблиц
select s.sql_id, 
    sum(s.executions_delta) AS e,
    round(sum(s.elapsed_time_delta)     / greatest(sum(s.executions_delta), 1) / 1e6, 4) AS ela,
    (select substr(t.sql_text, 1, 4000) from dba_hist_sqltext t where t.sql_id = s.sql_id) sql_text
from dba_hist_sqlstat s 
where s.parsing_schema_name <> 'SYS'
    and s.sql_id in (
        select sql_id from dba_hist_sql_plan where operation = 'TABLE ACCESS' and options = 'FULL' and object_owner <> 'SYS' and object_name like '%UBRR%')
group by s.sql_id
order by ela desc nulls last;