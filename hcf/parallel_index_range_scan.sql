-- https://www.sql.ru/forum/1321768/index-range-scan-in-parallel
with irs as (
  select/*+ inline */ *
  from (
     select
     rowid rid
     from tentry C
     where c.branch = 1
      AND c.operdate BETWEEN date'2019-04-01' - (14 + 1) AND date'2019-04-01' - 1
     union all select rowid from tentry where 1=0 
  )
)
select/*+ 
   no_merge(irs)
   leading(irs c)
   parallel(irs 8)
   no_adaptive_pl an
*/
 *
from irs, tentry C
where irs.rid = c.rowid 
and "C".isdelete=0;
