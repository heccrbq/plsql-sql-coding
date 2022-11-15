/**********************************************************************************************
  Родные оракловые коллекции, которые можно поискать по набору атрибутов:
  cnt - общее количество атрибутов в коллекции;
  cnt_varchar2 - количество строковых атрибутов;
  cnt_number - количество числовых атрибутов;
  cnt_date - количество временных атрибутов.
**********************************************************************************************/
select
  ct.owner owner_list,
  ct.type_name type_name_list,
  subq.owner,
  subq.type_name,
  subq.attr_name,
  subq.attr_type_name,
  subq.attr_no,
  subq.length,
  subq.precision,
  subq.scale,
  subq.character_set_name
from sys.dba_coll_types ct,
  (
    select dta.*, 
      count(1)over(partition by dta.type_name) cnt,
      count(decode(dta.attr_type_name, 'VARCHAR2', 1))over(partition by dta.type_name) cnt_varchar2,
      count(decode(dta.attr_type_name, 'NUMBER', 1))over(partition by dta.type_name) cnt_number,
      count(decode(dta.attr_type_name, 'DATE', 1))over(partition by dta.type_name) cnt_date
    from sys.dba_type_attrs dta
--    where dta.owner = 'SYS'
  )subq  
where ct.elem_type_name= subq.type_name
  and cnt = 2
  and (cnt_varchar2 = 1 and cnt_number = 1 and cnt_date = 0)
order by type_name_list,
  attr_no;






-- owner  : [null | <value>] : for example, 'SYS'
-- fixed : [Y | N] : Y - количество полей, равно сумме количества из attrs, N - количество полей любое, главное, чтоы присутствовали attrs
-- attrs : список типов данных атрибутов, которые должны присутствовать в типе
with source as (
    -- найти тип, владелец которого <ЛЮБОЙ>, в типе 3 поля, 2 из которых имеют типа VARCHAR2, одно поле имеет тип NUMBER
    select null owner, 'Y' fixed, sys.ku$_objnumnamset(sys.ku$_objnumnam(name => 'VARCHAR2', obj_num => 2), 
                                                       sys.ku$_objnumnam(name => 'NUMBER',   obj_num => 1), 
                                                       sys.ku$_objnumnam(name => 'DATE',     obj_num => 0)) attrs from dual
)

select * from source;
