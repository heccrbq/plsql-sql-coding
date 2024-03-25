declare
    l_sql_text clob := q'[
        SELECT ROWIDTOCHAR(A.ROWID), C.TYPE FROM TACCOUNT A, TCONTRACTITEM I, TCONTRACT C WHERE A.BRANCH = :B1 AND ( EXISTS ( SELECT C1.BRANCH FROM TACC2CARD C1 WHERE C1.BRANCH = A.BRANCH AND C1.ACCOUNTNO = A.ACCOUNTNO ) OR EXISTS ( SELECT /*+ ORDERED USE_NL(Ccc CustProd RefreshCustProd) INDEX_ASC(CCC PK_ACC2CUSTOMER) */ CCC.BRANCH FROM TACC2CUSTOMER CCC WHERE CCC.BRANCH = A.BRANCH AND CCC.ACCOUNTNO = A.ACCOUNTNO ) ) AND ( ( A.UPDATESYSDATE > :B2 ) ) AND I.BRANCH (+) = A.BRANCH AND I.ITEMTYPE (+) = 1 AND I.KEY (+) = A.ACCOUNTNO AND C.BRANCH (+) = I.BRANCH AND C.NO (+) = I.NO ORDER BY 2
        ]';
    l_sql_task varchar2(50);
begin
    l_sql_task := dbms_sqltune.create_tuning_task(
        sql_text => l_sql_text,
        bind_list => sql_binds(anydata.convertnumber(1), anydata.convertdate(date'2022-05-01')), -- anydata.convertvarchar2('1497450198')
        user_name => 'A4M',
        scope => 'COMPREHENSIVE',
        time_limit => 3600,
        task_name => 'dbykov_tuning_task',
        description => 'test test');
end;
/

begin
    dbms_sqltune.execute_tuning_task(task_name => 'dbykov_tuning_task');
end;
/

/*
begin
    dbms_sqltune.drop_tuning_task(task_name => 'dbykov_tuning_task');
end;
/
*/

select dbms_sqltune.report_tuning_task(task_name => 'dbykov_tuning_task') from dual;
