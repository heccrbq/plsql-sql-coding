prompt
prompt <<<<<<<<<<<<<<< Index of table &1 >>>>>>>>>>>>>>>
prompt

set pagesize 6000 verify off feedback off

column index_name format a30
column index_type format a10
column uniqueness format a10
column column_name format a20
break on index_name on uniqueness skip 1 on report

select
  i.index_name,i.index_type,i.uniqueness uniqueness,c.column_name
 from all_indexes i, all_ind_columns c
 where i.index_name=c.index_name and i.table_name=upper('&1')
 and c.index_owner=i.owner
 order by i.index_name,i.uniqueness,c.column_position;
exit
