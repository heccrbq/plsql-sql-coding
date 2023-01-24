with function plshprof(p_filename in varchar2) return clob
    is
        c_location constant varchar2(16) := 'PROFILER_DIR';
        l_clob     clob;
    begin
        dbms_hprof.analyze(location    => c_location,
                           filename    => p_filename,
                           report_clob => l_clob);
        
        return l_clob;
    end;
source as (
    select 'hprof_rtwr_1546469566_3.txt' filename from dual
)
select 
    substr(s.filename, 1, instr(s.filename, '.', -1)) || 'html' file#,
    plshprof(p_filename => s.filename) output 
from source s;
/
