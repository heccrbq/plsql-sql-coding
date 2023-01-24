with 
    function plshprof_report (p_filename in varchar2) return clob
    is
        c_location constant varchar2(16) := 'PROFILER_DIR';
        l_clob     clob;
    begin
        dbms_hprof.analyze(location    => c_location,
                           filename    => p_filename,
                           report_clob => l_clob);
        
        return l_clob;
    end;
select plshprof_report(p_filename => 'hprof_rtwr_1546469566_3.trc') from dual;
