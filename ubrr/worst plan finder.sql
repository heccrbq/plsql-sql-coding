-- INDEX RANGE SCAN с 30% кардинальностью > TABLE ACCESS FULL
-- пискать индексы, построенные на одних и тех же полях, только в разном поорядке.
-- INDEX SKIP SCAN
-- запросы с минимум 2мя разными планами
-- неиспользуемые индексы
-- жирные распухшие таблицы 
-- распухшие индексы
-- поискать запросы с high loaded version of child numbers

-- поискать места где используется коллекция PICKLER FETCH и прикрутить туда ASSOCIATE STATISTICS




with settings as (
    select 0.3 /*30%*/ threshold from dual
)
select 
    s.sql_id, 
    s.plan_hash_value, 
    pl.child_number,
    s.executions,
--    o.object_name, 
--    s.program_line#, 
    round( 100 * s.user_io_wait_time/greatest(elapsed_time,1), 2) io_pct, 
    round(s.user_io_wait_time / greatest(s.executions,1) / 1e6) io_time,
    pl.id plan_line_id,
    pl.operation, 
    pl.options, 
    pl.object_owner || '.' || pl.object_name object, 
    pl.cardinality,
    ind.num_rows ind_num_rows, 
    ind.distinct_keys , 
    tab.num_rows tab_num_rows,
    pl.access_predicates, 
    pl.filter_predicates 
from v$sql_plan pl
    join dba_indexes ind on ind.index_name = pl.object_name
    join dba_tables tab on tab.table_name = ind.table_name
    left join v$sqlarea s on s.sql_id = pl.sql_id 
                         and s.plan_hash_value = pl.plan_hash_value 
--                         and s.child_number = pl.child_number
    left join dba_objects o on o.object_id = s.program_id
    cross join settings
where pl.operation = 'INDEX' 
    and pl.options in ('RANGE SCAN', 'SKIP SCAN')
    and pl.object_owner <> 'SYS'
    and pl.cardinality / ind.num_rows > settings.threshold
	and ind.num_rows <> 0
order by cardinality desc;









select * From v$sql_plan where sql_id = '16k6ju2khyrg7';


select coalesce(dt.owner, di.table_owner) owner, coalesce(dt.table_name, di.table_name) table_namae, 
    sp.operation, sp.options, sp.object_owner, sp.object_name, regexp_substr(sp.object_alias,'^[^@]+') object_alias, sp.object_type,
    (select
        listagg(
            coalesce(
                -- 1
                dbms_xmlgen.convert(
                    xmlquery('for $i in //*
                        return $i/text()' 
                        passing dbms_xmlgen.getxmltype(
                            'select column_expression from dba_ind_expressions 
								where index_owner = ''' || ic.index_owner || '''
                                  and index_name  = ''' || ic.index_name  || '''
                                  and column_position = ''' || ic.column_position || '''') returning content 
                      ).getstringval(),1),
                -- 2
                ic.column_name
            ),
        ', ')within group(order by ic.column_position)
    from dba_ind_columns ic where ic.index_owner = di.owner and ic.index_name = di.index_name) column_list,
    sp.access_predicates, sp.filter_predicates
from v$sql_plan sp 
    left join dba_tables dt on dt.owner = sp.object_owner and dt.table_name = sp.object_name and sp.object_type = 'TABLE'
    left join dba_indexes di on di.owner = sp.object_owner and di.index_name = sp.object_name and sp.object_type = 'INDEX'
where sql_id = '16k6ju2khyrg7'
    and operation in ('TABLE ACCESS','INDEX');

select listagg(coalesce(die.column_expression, dic.column_name, ', '))within group(order by dic.column_position)
--dic.*, die.column_expression 
from dba_ind_columns dic left join dba_ind_expressions die on 
    die.index_owner = dic.index_owner and die.index_name = dic.index_name and die.column_position = dic.column_position
where dic.index_name = 'I_TSRORANKBELONGHIST_1';
select * From dba_ind_columns;





select distinct
                       nvl(
                       regexp_substr(
                          q'["T"."BRANCH"=:B3 (UPPER("T"."OPERDATE")=:B1 AND "T"."OBJECTNO"=:B2 AND "T"."OBJECTTYPE"=2 AND "T"."CATEGORY"='SIS')]'
--                         ,'("'||'T'||'"\.|[^.]|^)"([A-Z0-9#_$]+)"([^.]|$)'
                         ,'("'||'T'||'"\.|[^.]|^)"([A-Z0-9#_$]+)"([^.]|$)'
                         ,1
                         ,level
                         ,'i',2
                       ),' ')
                       col
                    from dual
                    connect by 
                       level<=regexp_count(
                                q'["T"."BRANCH"=:B3 ("T"."OPERDATE"=:B1 AND "T"."OBJECTNO"=:B2 AND "T"."OBJECTTYPE"=2 AND "T"."CATEGORY"='SIS')]'
                                ,'("'||'T'||'"\.|[^.]|^)"([A-Z0-9#_$]+)"([^.]|$)'
                              )


















--with 
--    function evaluate_index_usage()
select 
    --coalesce(dt.owner, di.table_owner) owner, coalesce(dt.table_name, di.table_name) table_namae, 
    sp.sql_id, sp.plan_hash_value phv, sp.child_number cn, sp.id, sp.parent_id, 
    sp.operation || ' ' || sp.options plan_operation, sp.object_owner || '.' || sp.object_name object#, regexp_substr(sp.object_alias,'^[^@]+') object_alias, sp.object_type,
--    (select
--        listagg(
--            coalesce(
--                -- 1
--                dbms_xmlgen.convert(
--                    xmlquery('for $i in //*
--                        return $i/text()' 
--                        passing dbms_xmlgen.getxmltype(
--                            'select column_expression from dba_ind_expressions 
--								where index_owner = ''' || ic.index_owner || '''
--                                  and index_name  = ''' || ic.index_name  || '''
--                                  and column_position = ''' || ic.column_position || '''') returning content 
--                      ).getstringval(),1),
--                -- 2
--                ic.column_name
--            ),
--        ', ')within group(order by ic.column_position)
--    from dba_ind_columns ic where ic.index_owner = di.owner and ic.index_name = di.index_name) column_list,
--    (select distinct
--       nvl(
--       regexp_substr(
--          q'["T"."BRANCH"=:B3 (UPPER("T"."OPERDATE")=:B1 AND "T"."OBJECTNO"=:B2 AND "T"."OBJECTTYPE"=2 AND "T"."CATEGORY"='SIS')]'
----                         ,'("'||'T'||'"\.|[^.]|^)"([A-Z0-9#_$]+)"([^.]|$)'
--         ,'("'||'T'||'"\.|[^.]|^)"([A-Z0-9#_$]+)"([^.]|$)'
--         ,1
--         ,level
--         ,'i',2
--       ),' ')
--       col
--    from dual
--    connect by 
--       level<=regexp_count(
--                q'["T"."BRANCH"=:B3 ("T"."OPERDATE"=:B1 AND "T"."OBJECTNO"=:B2 AND "T"."OBJECTTYPE"=2 AND "T"."CATEGORY"='SIS')]'
--                ,'("'||'T'||'"\.|[^.]|^)"([A-Z0-9#_$]+)"([^.]|$)'
--              )) predicate_list,
    sp.access_predicates, sp.filter_predicates
from v$sql_plan sp
--    left join dba_tables dt on dt.owner = sp.object_owner and dt.table_name = sp.object_name and sp.object_type = 'TABLE'
    left join dba_indexes di on di.owner = sp.object_owner and di.index_name = sp.object_name and sp.object_type = 'INDEX'
where sp.operation in ('TABLE ACCESS','INDEX')
--    and sp.sql_id = '16k6ju2khyrg7'
    and not exists (select 0 from v$sql s where s.child_address = sp.child_address and s.parsing_schema_name = 'SYS')
order by sp.child_address
    ;
    
    select * from v$sql where sql_id = '4ta4nfxhpnndz';
select distinct t.* from (
select 
    sp.sql_id, sp.id, sp.parent_id, 
    sp.operation || ' ' || sp.options plan_operation, sp.object_owner || '.' || sp.object_name object#, regexp_substr(sp.object_alias,'^[^@]+') object_alias, sp.object_type,
    sp.access_predicates, sp.filter_predicates
from v$sql_plan sp
where sp.operation in ('TABLE ACCESS','INDEX')
    and sp.sql_id = '16k6ju2khyrg7') t
    connect by prior id = parent_id;

 select * from v$sql_plan;   
select * from dba_indexes where table_name = 'TSRORANKBELONGHIST';
    
select * from v$sql_plan sp where sp.sql_id = '16k6ju2khyrg7';
select * from v$sql where sql_id = '4ta4nfxhpnndz';

select * from dba_source where lower(text) like  '%optimizer_mode%' and name = 'UBRR_STR_BKI_CREATE';
select * from dba_source where name = 'UBRR_STR_BKI_CREATE';


SELECT COFFER_STATUS FROM UBRR_CARD_OFFER WHERE CARD_UID = :B1 AND COFFER_STATUS IN ('32', '31');


SELECT --+parallel 
COUNT(1) FROM a4m.TSRORANKBELONGHIST T WHERE T.BRANCH = :B3 AND upper(T.CATEGORY) = 'SIS' AND T.OBJECTTYPE = 2 AND T.OBJECTNO = :B2 AND T.OPERDATE = :B1 
