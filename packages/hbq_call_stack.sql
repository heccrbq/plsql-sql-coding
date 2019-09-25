create or replace package hbq_call_stack is
    
    $if dbms_db_version.version >= 12 $then
        /**
         * =============================================================================================
         * Description
         * =============================================================================================
         */
        function subprogram return varchar2;
    $end
    
end hbq_call_stack;
/
create or replace package body hbq_call_stack is
    
    $if dbms_db_version.version >= 12 $then
        /**
         * =============================================================================================
         * Description
         * =============================================================================================
         */
        function subprogram return varchar2
        is
        begin
            return utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram (dynamic_depth => 2)); 
        end subprogram;
    $end
    
end hbq_call_stack;
/
