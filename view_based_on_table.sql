/**********************************************************************************************
  Создание view по имени ключевой таблицы один к одному.
  Правила именования таковы, что view_name отсекает букву T в первом слоге имени таблицы: 
  table_name FT_APPLICATION_FRAUD_RULE_AD => view name F_APPLICATION_FRAUD_RULE_AD 
**********************************************************************************************/
with source as
(
  select --+materialize
    col.owner,
    col.table_name,
    regexp_replace(col.table_name, '^(\S{1,2})T', '\1', 1, 1) view_name,
    col.column_name,
    col.column_id,
    max(col.column_id)over(partition by col.table_name) max_column_id,
    col_comm.comments
  from dba_tab_columns col,
    dba_col_comments col_comm
  where col.owner = 'OWNER_DWH'
    and col.table_name IN ('FT_APPLICATION_FRAUD_RULE_AD')
    and col_comm.owner(+) = col.owner
    and col_comm.table_name(+) = col.table_name
    and col_comm.column_name(+) = col.column_name
)
select --+ собираем view
  lower(view_name) || '.sql' file_name,
  'CREATE OR REPLACE force view ' 
  || lower(owner)
  || '.' 
  || lower(view_name)
  || ' AS' || chr(10) 
  || '--UTF8-BOM: české znaky: ěščřžýáíé a ruské znaky: йцгшщзфы a čínské znaky: 在该商店中不能修改贷款限度额' || chr(10) || '--nemazat !!!' || chr(10) || '--' || lpad('=',106,'=') || chr(10)
  || '    SELECT '
  || dbms_xmlgen.convert(xmlagg(xmlelement(table_name,lower(decode(column_id,1,null,'           ') || column_name), decode(column_id,max_column_id,null,','||chr(10))) order by column_id).extract('//text()').getclobval(),1)
  || chr(10) || '    FROM   ' 
  || lower(owner)
  || '.' 
  || lower(table_name)
  || ' WITH READ ONLY;' || chr(10) || chr(10)
  || (select 'COMMENT ON TABLE ' || lower(owner) || '.' || lower(view_name) || ' IS ' || case when regexp_like(comments,'''') then 'q''[' else '''' end || comments || case when regexp_like(comments,'''') then ']''' else '''' end || ';' from dba_tab_comments where table_name = source.table_name and owner = source.owner and table_type = 'TABLE')
  || chr(10) || chr(10)
  || dbms_xmlgen.convert(xmlagg(xmlelement(table_name,
        'COMMENT ON column ' || lower(owner) || '.' || lower(view_name) || '.' || lower(column_name) || ' IS ' || case when regexp_like(comments,'''') then 'q''[' else '''' end || comments || case when regexp_like(comments,'''') then ']''' else '''' end || ';' || chr(10)) order by column_id
      ).extract('//text()').getclobval(),1) ddl_script
from source
group by table_name, view_name, owner;
