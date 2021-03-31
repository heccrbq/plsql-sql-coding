-- рекурсия с PL/SQL
with function f (p number) return number
is
begin
    return p * case p when 1 then 1 else f(p-1) end;
end;
select f(5) from dual;
/
-- мат аппарат перемножегния
select trunc(exp(sum(ln(level)))) x from dual connect by level <= 5;
/
-- переменожение через Dynamic SQL
select xmltype(dbms_xmlgen.getxml('select ' || listagg(level,'*')within group(order by level) || ' from dual')).extract('//text()').getnumberval() x from dual connect by level <=5 group by 1;
/
-- Model
select *
from dual
model
dimension by (rownum r)
measures (cast(null as integer) s)
rules update iterate(5)(s[any] order by iteration_number = (iteration_number + 1) * nvl( s[1], 1));
/
-- рекурсивный WITH
with t(lvl,x) as (
    select 1, 1 from dual
    union all
    select lvl+1, lvl*x from t where  lvl <= 5)
select max(x)keep(dense_rank last order by lvl) x From t;
/
-- local XQuery функция
select value(xt).getnumberval() x from xmltable(
    'declare function local:recu($x) { 
        if ($x gt 1) then
            $x * local:recu($x - 1)
        else
            1
    };
    local:recu(xs:integer($n))' passing 5 as "n") xt;
