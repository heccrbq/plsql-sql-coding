select 
    m.branch, m.code, name, execdate, countline, execcount, count(distinct eh.execid) execcounthistory,
    round((max(systemdate)keep(dense_rank last order by eh.execid) - min(systemdate)keep(dense_rank last order by eh.execid)) * 86400) last_exec_duration_sec
from TBPM_MACROS m left join TBPM_EXECHISTORY eh on eh.branch = m.branch and eh.code_macros = m.code
group by m.branch, m.code, name, execdate, execcount, countline;



with source as (
    select 2 branch, 943 code_macros, 427127 execid from dual
)
select ml.no, min(eventtime) begin#, max(eventtime) end#
from tbpm_macros m 
    join tbpm_exechistory eh on eh.branch = m.branch and eh.code_macros = m.code
    join tbpm_macroline ml on ml.branch = eh.branch and ml.code_macros = eh.code_macros and ml.code = eh.code_macroline
    join tbpm_history h on h.branch = ml.branch and h.code_macros = ml.code_macros and h.execid = eh.execid and h.code_macroline = ml.code and h.code_cmd = ml.cmd
where (m.branch, m.code, eh.execid) in (select * from source)
group by m.branch, m.code, eh.execid, ml.no
order by h.no;


