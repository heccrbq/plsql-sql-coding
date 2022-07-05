declare
    l_sql_text clob := q'[
        select count(1) from TRETADJUSTTRAN TR WHERE TR.BRANCH = 1 AND NOT EXISTS (SELECT TD.DOCNO FROM TDOCUMENT TD WHERE TD.BRANCH = TR.BRANCH AND TD.DOCNO = TR.DOCNO)
        ]';
    l_sql_task varchar2(50);
begin
    l_sql_task := dbms_sqltune.create_tuning_task(
        sql_text => l_sql_text,
--        bind_list => sql_binds(anydata.convertnumber(1), anydata.convertdate(date'2022-05-01')),
        bind_list => null,
        user_name => 'A4M',
        scope => 'COMPREHENSIVE',
        time_limit => 3600,
        task_name => 'heccrbq_tuning_task',
        description => 'task for the query tuning');
end;
/

begin
    dbms_sqltune.execute_tuning_task(task_name => 'heccrbq_tuning_task');
end;
/

begin
    dbms_sqltune.drop_tuning_task(task_name => 'heccrbq_tuning_task');
end;
/

select dbms_sqltune.report_tuning_task(task_name => 'heccrbq_tuning_task') from dual;
