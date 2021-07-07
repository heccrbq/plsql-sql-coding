/**
 * =============================================================================================
 * Среднее время работы указанного запроса в каждом из снепшотов.
 * =============================================================================================
 * @param   sql_id   				Уникальный идентификатор запроса
 * @param   sql_plan_hash_value		Хэш значение плана выполнения искомого запроса
 * =============================================================================================
 * Описание полей:
 *	- owner : 
 *  - table_name : 
 *  - partition_name : 
 *  - # : 
 *  - stattype_locked : 
 *  - astale_stats : 
 *	- global_stats :
 *	- user_stats :
 *	- num_rows :
 *	- blocks :
 *	- empty_blocks :
 *	- avg_row_len :
 *	- avg_space :
 *	- last_analyzed :
 * =============================================================================================
 */
select
    t.owner,
    t.table_name,
    t.partition_name,
    t.partition_position as "#",
    t.stattype_locked,
    t.stale_stats,
    t.global_stats,
    t.user_stats,
    t.num_rows,
    t.blocks,
    t.empty_blocks,
    t.avg_row_len,
    t.avg_space,
    t.last_analyzed 
from dba_tab_statistics t 
where t.owner = 'A4M' /*p_table_owner*/
  and t.table_name in ('TDOCUMENT', 'TENTRY')/*p_table_name*/;
  

select 
    ix.owner,
    ix.table_name,
    ix.index_name,
    ix.num_rows,
    ix.distinct_keys,
    ix.blevel,
    ix.leaf_blocks,
    ix.clustering_factor,
    ix.last_analyzed,
    ix.global_stats,
    ix.user_stats,
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
    from dba_ind_columns ic where ix.owner = ic.index_owner and ix.index_name = ic.index_name) column_list
from dba_indexes ix
where ix.table_owner = 'A4M'
    and ix.table_name in ('TBOPRECFIELD')
order by ix.table_name,
    ix.index_name;


with function raw_to_data(p_data_type varchar2, p_value raw) return varchar2
is
    l_date date;
    l_number number;
    l_varchar2 varchar2(4000);
begin
    if p_data_type = 'NUMBER' 
        then dbms_stats.convert_raw_value(p_value, l_number);
    elsif p_data_type = 'DATE' 
        then dbms_stats.convert_raw_value(p_value, l_date);
    elsif p_data_type = 'VARCHAR2' 
        then dbms_stats.convert_raw_value(p_value, l_varchar2);
    end if;
    
    return coalesce(to_char(l_number), to_char(l_date, 'dd.mm.yyyy hh24:mi:ss'), l_varchar2);
end;
select tc.table_name,
    tc.column_name,
    cs.num_distinct,
    tc.data_type,
--    cs.low_value,
    raw_to_data(tc.data_type, cs.low_value) low_value,
--    cs.high_value,
    raw_to_data(tc.data_type, cs.high_value) high_value,
    cs.density,
    cs.num_nulls,
    cs.num_buckets,
    cs.last_analyzed,
    cs.sample_size,
    cs.global_stats,
    cs.user_stats,
    cs.avg_col_len,
    cs.histogram
from dba_tab_col_statistics cs ,
    dba_tab_columns tc
where tc.owner = 'A4M'
    and tc.table_name in ('TDOCUMENT', 'TENTRY')
    and tc.owner = cs.owner(+)
    and tc.table_name = cs.table_name(+)
    and tc.column_name = cs.column_name(+)
order by tc.table_name, tc.column_id;











set serveroutput on size unlimited
declare
    l_sql_id varchar2(30) := 'gawxxn8du00jq';
    l_sql_plan_hash_value integer := 3416516938;
    l_sql_child_number integer := 0;
    --
    l_sql_info boolean default true;
    l_table_stats boolean default true;
    l_index_stats boolean default true;
    l_table_rawdata boolean default false;
    l_index_rawdata boolean default false;
    --
    crlf varchar2(10) := chr(13) || chr(10);
    --
    function raw_to_data(p_data_type varchar2, p_value raw) return varchar2
    is
        l_date date;
        l_number number;
        l_varchar2 varchar2(4000);
        pragma udf;
    begin
        if p_data_type = 'NUMBER' 
            then dbms_stats.convert_raw_value(p_value, l_number);
        elsif p_data_type = 'DATE' 
            then dbms_stats.convert_raw_value(p_value, l_date);
        elsif p_data_type = 'VARCHAR2' 
            then dbms_stats.convert_raw_value(p_value, l_varchar2);
        end if;
        
        return coalesce(to_char(l_number), to_char(l_date, 'dd.mm.yyyy hh24:mi:ss'), l_varchar2);
    end raw_to_data;
    --
    procedure print(col1 varchar2 default null, len1 integer default null, val1 varchar2 default null,      col2 varchar2 default null, len2 integer default null, val2 varchar2 default null,
                    col3 varchar2 default null, len3 integer default null, val3 varchar2 default null,      col4 varchar2 default null, len4 integer default null, val4 varchar2 default null,
                    col5 varchar2 default null, len5 integer default null, val5 varchar2 default null,      col6 varchar2 default null, len6 integer default null, val6 varchar2 default null,
                    col7 varchar2 default null, len7 integer default null, val7 varchar2 default null,      col8 varchar2 default null, len8 integer default null, val8 varchar2 default null,
                    col9 varchar2 default null, len9 integer default null, val9 varchar2 default null,
                    col10 varchar2 default null, len10 integer default null, val10 varchar2 default null,   col11 varchar2 default null, len11 integer default null, val11 varchar2 default null,
                    col12 varchar2 default null, len12 integer default null, val12 varchar2 default null)
    is
    begin
        if col1 is not null then
            -- Header
            dbms_output.put_line(lpad('-', nvl(len1,0) + sign(nvl(len1,0)) + nvl(len2,0) + sign(nvl(len2,0)) + nvl(len3,0) + sign(nvl(len3,0)) + 
                                           nvl(len4,0) + sign(nvl(len4,0)) + nvl(len5,0) + sign(nvl(len5,0)) + nvl(len6,0) + sign(nvl(len6,0)) + 
                                           nvl(len7,0) + sign(nvl(len7,0)) + nvl(len8,0) + sign(nvl(len8,0)) + nvl(len9,0) + sign(nvl(len9,0)) + 
                                           nvl(len10,0) + sign(nvl(len10,0)) + nvl(len11,0) + sign(nvl(len11,0)) + nvl(len12,0) + sign(nvl(len12,0)) + 13, '-'));
            dbms_output.put_line('| ' || lpad(col1, len1) || ' | ' || lpad(col2, len2) || ' | ' || lpad(col3, len3) ||
                                ' | ' || lpad(col4, len4) || ' | ' || lpad(col5, len5) || ' | ' || lpad(col6, len6) ||
                                ' | ' || lpad(col7, len7) || ' | ' || lpad(col8, len8) || ' | ' || lpad(col9, len9) ||
                                ' | ' || lpad(col10, len10) || ' | ' || lpad(col11, len11) || ' | ' || lpad(col12, len12) ||' |');
            dbms_output.put_line(lpad('-', nvl(len1,0) + sign(nvl(len1,0)) + nvl(len2,0) + sign(nvl(len2,0)) + nvl(len3,0) + sign(nvl(len3,0)) + 
                                           nvl(len4,0) + sign(nvl(len4,0)) + nvl(len5,0) + sign(nvl(len5,0)) + nvl(len6,0) + sign(nvl(len6,0)) +
                                           nvl(len7,0) + sign(nvl(len7,0)) + nvl(len8,0) + sign(nvl(len8,0)) + nvl(len9,0) + sign(nvl(len9,0)) + 
                                           nvl(len10,0) + sign(nvl(len10,0)) + nvl(len11,0) + sign(nvl(len11,0)) + nvl(len12,0) + sign(nvl(len12,0)) + 13, '-'));
            -- Body
            dbms_output.put_line('| ' || lpad(nvl(val1, ' '), len1) || ' | ' || lpad(nvl(val2, ' '), len2) || ' | ' || lpad(nvl(val3, ' '), len3) ||
                                ' | ' || lpad(nvl(val4, ' '), len4) || ' | ' || lpad(nvl(val5, ' '), len5) || ' | ' || lpad(nvl(val6, ' '), len6) || 
                                ' | ' || lpad(nvl(val7, ' '), len7) || ' | ' || lpad(nvl(val8, ' '), len8) || ' | ' || lpad(nvl(val9, ' '), len9) ||
                                ' | ' || lpad(nvl(val10, ' '), len10) || ' | ' || lpad(nvl(val11, ' '), len11) || ' | ' || lpad(nvl(val12, ' '), len12) || ' |');
            -- Footer
            dbms_output.put_line(lpad('-', nvl(len1,0) + sign(nvl(len1,0)) + nvl(len2,0) + sign(nvl(len2,0)) + nvl(len3,0) + sign(nvl(len3,0)) + 
                                           nvl(len4,0) + sign(nvl(len4,0)) + nvl(len5,0) + sign(nvl(len5,0)) + nvl(len6,0) + sign(nvl(len6,0)) + 
                                           nvl(len7,0) + sign(nvl(len7,0)) + nvl(len8,0) + sign(nvl(len8,0)) + nvl(len9,0) + sign(nvl(len9,0)) + 
                                           nvl(len10,0) + sign(nvl(len10,0)) + nvl(len11,0) + sign(nvl(len11,0)) + nvl(len12,0) + sign(nvl(len12,0)) + 13, '-'));
        else 
            return;
        end if;
--        if col2 is not null then
        
    end;
begin
    if l_sql_info then
        for i in (
            select sql_id, plan_hash_value, child_number from v$sql where sql_id = l_sql_id and plan_hash_value = l_sql_plan_hash_value and child_number = l_sql_child_number)
        loop
            dbms_output.put_line('SQL_ID = ' || i.sql_id || ', sql plan hash value = ' || i.plan_hash_value || ', sql child number = ' || i.child_number || crlf);
        end loop;
    end if;
    
    -- Собираем статистику по всем таблицам, используемым в запросе
    if l_table_stats then
        for i in (
            select /*+push_pred (ts)*/
                ts.owner,
                ts.table_name,
                ts.partition_name,
                ts.partition_position,
                ts.stattype_locked,
                ts.stale_stats,
                ts.global_stats,
                ts.user_stats,
                ts.num_rows,
                ts.blocks,
                ts.empty_blocks,
                ts.avg_row_len,
                ts.avg_space,
                ts.last_analyzed 
            from v$sql_plan sp,
                all_objects o,
                all_tab_statistics ts
            where sp.sql_id = l_sql_id and sp.plan_hash_value = l_sql_plan_hash_value and sp.child_number = l_sql_child_number 
                and o.object_id = sp.object# and o.object_type = 'TABLE'
                and ts.owner = o.owner and ts.table_name = o.object_name and ts.object_type = o.object_type)
        loop
            print ( col1 => 'Owner',        len1 => 5,    val1 => i.owner,
                    col2 => 'Table name',   len2 => 30,   val2 => i.table_name, 
                    col3 => 'Part name',    len3 => 10,   val3 => i.partition_name,
                    col4 => '#',            len4 => 5,    val4 => i.partition_position,
                    col5 => 'Stattype',     len5 => 10,   val5 => i.stattype_locked,
                    col6 => 'Stale stats',  len6 => 15,   val6 => i.stale_stats );
        end loop;
    end if;
end;
/
           
