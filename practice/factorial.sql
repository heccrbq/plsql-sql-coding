-- рекурсия с PL/SQL
with function f (p number) return number
is
begin
    if p = 0 then
        return 1;
    else 
        return p * f(p-1);
    end if;
end;
select f(5/*:argument*/) x from dual;
/
-- мат аппарат перемножения
select trunc(exp(sum(ln(level)))) x from dual connect by level <= 5/*:argument*/;
/
-- переменожение через Dynamic SQL
select 
    xmltype(dbms_xmlgen.getxml('select ' || listagg(level,'*')within group(order by level) || ' from dual')).extract('//text()').getnumberval() x 
from dual connect by level <=5/*:argument*/ group by 1;
/
-- Model
select s
from dual
model
dimension by (1 r)
measures (1 s)
rules update iterate(5/*:argument*/)(s[r] order by iteration_number = (iteration_number + 1) * s[1]);
/
-- рекурсивный WITH
with t(lvl,x) as (
    select 1, 1 from dual
    union all
    select lvl+1, lvl*x from t where  lvl <= 5/*:argument*/)
select max(x)keep(dense_rank last order by lvl) x From t;
/
-- local XQuery функция
select value(xt).getnumberval() x from xmltable(
    'declare function local:recu($x) { 
        if ($x gt 0) then
            $x * local:recu($x - 1)
        else
            1
    };
    local:recu(xs:integer($n))' passing 5/*:argument*/ as "n") xt;
