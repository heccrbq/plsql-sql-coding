create or replace package ci_diagnostics as
    
    -- Author: 
    -- License: 
    
    -- types
--    type t_session_statements is record (
--        sql_id               v$active_session_history.sql_id%type,
--        sql_exec_id          integer,
--        in_connection_mgmt   integer,
--        in_parse             integer,
--        in_hard_parse        integer,
--        in_sql_execution     integer,
--        in_plsql_rpc         integer,
--        in_plsql_compilation integer,
--        in_java_execution    integer,
--        in_bind              integer,
--        in_cursor_close      integer,
--        in_sequence_load     integer
--    );
    
    -- cursors
    cursor cur_session_statements(p_session_id         in number, 
                                  p_session_serial     in number, 
                                  p_session_start_time in date)
--        return t_session_statements
    is
        select 
            ash.sql_id,
            count(distinct ash.sql_exec_id) sql_exec_id,
            count(nullif(ash.in_connection_mgmt, 'N')) in_connection_mgmt,
            count(nullif(ash.in_parse, 'N')) in_parse,
            count(nullif(ash.in_hard_parse, 'N')) in_hard_parse,
            count(nullif(ash.in_sql_execution, 'N')) in_sql_execution,
            count(nullif(ash.in_plsql_rpc, 'N')) in_plsql_rpc,
            count(nullif(ash.in_plsql_compilation, 'N')) in_plsql_compilation,
            count(nullif(ash.in_java_execution, 'N')) in_java_execution,
            count(nullif(ash.in_bind, 'N')) in_bind,
            count(nullif(ash.in_cursor_close, 'N')) in_cursor_close,
            count(nullif(ash.in_sequence_load, 'N')) in_sequence_load
        from v$active_session_history ash
        where ash.session_id = p_session_id
            and ash.session_serial# = p_session_serial
            and (ash.sample_time >= p_session_start_time or p_session_start_time is null)
        group by ash.sql_id;
    
    
    type tbl_session_statements is table of cur_session_statements%rowtype;
    

    /**
    @param p_session_id
    @param p_sessrion_serial
	@param p_session_start_time
    */
    function display_session_statements (p_session_id         in number, 
                                         p_session_serial     in number, 
                                         p_session_start_time in date default null) 
    return tbl_session_statements;

end ci_diagnostics;
/
create or replace package body ci_diagnostics as

    function display_session_statements (p_session_id         in number, 
                                         p_session_serial     in number, 
                                         p_session_start_time in date default null) 
    return tbl_session_statements
    is
        l_result$ tbl_session_statements;
    begin
        open cur_session_statements(p_session_id         => p_session_id,
                                    p_session_serial     => p_session_serial,
                                    p_session_start_time => p_session_start_time);
            fetch cur_session_statements bulk collect into l_result$;
        close cur_session_statements;

        return l_result$;
--    exception
--        when no_data_found then
--            return 0; --new tbl_session_statements();
    end display_session_statements;

end ci_diagnostics;
/