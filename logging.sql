alter session set nls_length_semantics=char;

drop table tubrr_getinfo_log purge;
create table tubrr_getinfo_log(
    log_id          integer generated always as identity not null constraint tubrr_getinfo_log_pk primary key using index reverse tablespace indx disable,
    log_time        timestamp,
    log_msg         varchar2(255),
    sid             number,
    serial#         number,
    username        varchar2(128),
    osuser          varchar2(128),
    host            varchar2(64),
    ip_address      varchar2(20),
    terminal        varchar2(30),
    module          varchar2(48),
    content         clob,
    call_stack      varchar2(1000),
    subprogram      varchar2(255),
    error_stack     varchar2(1000),
    error_backtrace varchar2(1000)
) pctfree 0
partition by range(log_time) interval(numtoyminterval(1,'month')) (partition p_default values less than (date'2023-01-01'));


create or replace procedure ubrr_getinfo_log(p_log_msg in varchar2 default null, p_log_content in clob default null) is
    pragma autonomous_transaction;
    l_ubrr_getinfo_log tubrr_getinfo_log%rowtype;
begin
--    l_ubrr_getinfo_log.log_id          := "A4M"."ISEQ$$_42828766".nextval;
    l_ubrr_getinfo_log.log_time        := systimestamp;
    l_ubrr_getinfo_log.log_msg         := substr(p_log_msg, 1, 255);    
    l_ubrr_getinfo_log.sid             := sys_context('userenv', 'sid');
    l_ubrr_getinfo_log.serial#         := null;
    l_ubrr_getinfo_log.username        := sys_context('userenv', 'session_user');
    l_ubrr_getinfo_log.osuser          := sys_context('userenv', 'os_user');
    l_ubrr_getinfo_log.host            := sys_context('userenv', 'host');
    l_ubrr_getinfo_log.ip_address      := sys_context('userenv', 'ip_address');
    l_ubrr_getinfo_log.terminal        := sys_context('userenv', 'terminal');
    l_ubrr_getinfo_log.module          := sys_context('userenv', 'module');
    l_ubrr_getinfo_log.content         := p_log_content;
    l_ubrr_getinfo_log.call_stack      := substr(dbms_utility.format_call_stack, 1, 1000);
    l_ubrr_getinfo_log.subprogram      := utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(dynamic_depth => 2)) || ' (line: ' || utl_call_stack.unit_line(dynamic_depth => 2) || ')';
    l_ubrr_getinfo_log.error_stack     := substr(dbms_utility.format_error_stack, 1, 1000);
    l_ubrr_getinfo_log.error_backtrace := substr(dbms_utility.format_error_backtrace, 1, 1000);
    
    insert into tubrr_getinfo_log values l_ubrr_getinfo_log;
    commit;
end ubrr_getinfo_log;
/
