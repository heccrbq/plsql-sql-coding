select * from gv$version;

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
  and t.table_name in ( 'TCLERK',
                        'TCONTRACTTYPE',
                        'TPLANACCOUNT',
                        'TCONTRACT',
                        'TCONTRACTITEM',
                        'TDOCUMENT',
                        'TENTRY' )/*p_table_name*/
order by table_name;

select 
    ix.owner,
    ix.table_name,
    ix.index_name,
    ix.index_type,
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
where ix.table_owner = 'A4M' /*p_table_owner*/
    and ix.table_name in ( 'TCLERK',
                           'TCONTRACTTYPE',
                           'TPLANACCOUNT',
                           'TCONTRACT',
                           'TCONTRACTITEM',
                           'TDOCUMENT',
                           'TENTRY' ) /*p_table_name*/
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
where tc.owner = 'A4M' /*p_table_owner*/
    and tc.table_name in ( 'TCLERK',
                           'TCONTRACTTYPE',
                           'TPLANACCOUNT',
                           'TCONTRACT',
                           'TCONTRACTITEM',
                           'TDOCUMENT',
                           'TENTRY' ) /*p_table_name*/
    and tc.owner = cs.owner(+)
    and tc.table_name = cs.table_name(+)
    and tc.column_name = cs.column_name(+)
order by tc.table_name, tc.column_id;
