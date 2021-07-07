-- member of vs select from
           
drop sequence dropme_seq;
create sequence dropme_seq;
create or replace type dropme_type is table of number;
/
create or replace function dropme_func return dropme_type is
v number;
d dropme_type;
begin
    select level 
    bulk collect into d
    from dual
    connect by level <= 1e5;
    v := dropme_seq.nextval;
    return d;
end;
/
drop table dropme;
create table dropme as select level cv from dual connect by level <= 1000;

select dropme_seq.nextval from dual;

--explain plan for
select count(1) From dropme where cv member of dropme_func;
--
select count(1) from dropme where cv in (select * from table(dropme_func) t);






SET SERVEROUTPUT ON 
DECLARE
  l_clob CLOB;
BEGIN
  DBMS_UTILITY.expand_sql_text (
    input_sql_text  => '',
    output_sql_text => l_clob
  );

  DBMS_OUTPUT.put_line(l_clob);
END;
/




select * from xmltable(
    'let $r := 1
    for $i in (1 to xs:integer(.))
    return $r * $i' passing 5 columns "." varchar2(50)) xt;
	
	
	
	
	
	
  
  
  
select status,
    plan_line_id, lpad(' ', 4*plan_depth) || plan_operation || ' ' || plan_options, plan_object_name, --plan_cost, plan_cardinality, --plan_object_type,
    starts, output_rows,    
    first_refresh_time, last_refresh_time, first_change_time, last_change_time
from v$SQL_PLAN_MONITOR where sql_id = 'd74z9jk9uwj3n';
