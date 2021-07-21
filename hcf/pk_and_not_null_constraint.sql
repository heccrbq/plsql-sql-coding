

select 
    c1.table_name
    ,c1.constraint_name
    ,c2.column_name
    ,c3.search_condition_vc
from user_constraints c1
    inner join user_cons_columns c2 on c2.constraint_name = c1.constraint_name
    left  join user_constraints c3 on c3.table_name = c2.table_name and c3.search_condition_vc = '"' || c2.column_name || '" IS NOT NULL'
where c1.constraint_type = 'P'
    and c3.search_condition_vc is null
order by 1, 3;
