select * from dba_hist_sqltext where sql_id = 'd9vx45z6jq89b';


select * From dba_hist_sqlstat where sql_id = 'd9vx45z6jq89b' order by snap_id desc;

EXECUTIONS_TOTAL    ELAPSED_TIME_TOTAL    BUFFER_GETS_TOTAL
------------------- --------------------- -----------------
                772           24147163964          89028523


select 24147163964/772 ela, 89028523/772 bg from dual; -- 31.3 sec / 115322 buffers

-- 46 rows selected
-- sort by duration
select * from dba_hist_reports where component_name = 'sqlmonitor' and key1 = 'd9vx45z6jq89b' and period_start_time >= date'2023-11-13' order by to_number(substr(key4,1,instr(key4,'#')-1)) desc;

-- 129 sec
select avg(to_number(substr(key4,1,instr(key4,'#')-1))) from dba_hist_reports where component_name = 'sqlmonitor' and key1 = 'd9vx45z6jq89b' and period_start_time >= date'2023-11-13';


-- get binds
select xt.* from dba_hist_reports_details rd, 
    xmltable('//binds/bind' passing xmltype(rd.report) columns name varchar2(10)  path '@name', 
                                                              dty number path '@dty',
                                                              dtystr varchar2(255) path '@dtystr',
                                                              value varchar2(255) path '.')xt
where rd.report_id = 1212241
order by name desc;




with function execute_statement(p_report_id number) return number is
    type typ is record(
        name varchar2(10), 
        dty number,
        dtystr varchar2(255),
        value varchar2(255));
    type tbl_typ is table of typ index by binary_integer;
    l_binds tbl_typ;
    --
    l_index  number;
    l_time   number;
    l_result number;
    l_sql varchar2(4000) := q'[
SELECT -- run5
    SUM(t.value)
FROM a4m.ubrr_contract_cess u
    JOIN a4m.tcontractitem ti ON ( ti.branch = u.branch
                               AND ti.no = u.contractno )
    JOIN a4m.tentry        t ON ( t.branch = ti.branch
                       AND t.creditaccount = ti.key )
    JOIN a4m.tdocument     d ON ( d.branch = t.branch
                          AND d.docno = t.docno )
WHERE
        1 = 1
    AND u.branch = :b6
    AND u.cessnumber = :b5
    AND u.enddate = TO_DATE('01.01.4000', 'dd.mm.yyyy')
    AND d.opdate = :b4
    AND d.docno >= :b3
    AND t.debitaccount LIKE :b2 || '%'
    AND t.creditaccount LIKE :b1 || '%']';
begin
    for i in (
        select xt.*
    from dba_hist_reports_details rd, 
        xmltable('//binds/bind' passing xmltype(rd.report) columns name varchar2(10)  path '@name', 
                                                                    dty number        path '@dty',
                                                                 dtystr varchar2(255) path '@dtystr',
                                                                  value varchar2(255) path '.')xt
    where rd.report_id = p_report_id)
    loop
        l_index := regexp_substr(i.name,'\d+');
        l_binds(l_index).name :=  i.name;
        l_binds(l_index).dty := i.dty;
        l_binds(l_index).dtystr := i.dtystr;
        l_binds(l_index).value := i.value;
    end loop;
    
    dbms_output.put_line('OK');

    l_time := dbms_utility.get_time;
    execute immediate l_sql into l_result 
        using to_number(l_binds(6).value), 
              to_number(l_binds(5).value), 
              to_date(l_binds(4).value, 'mm/dd/yyyy hh24:mi:ss'), 
              to_number(l_binds(3).value), 
              l_binds(2).value, 
              l_binds(1).value;
    
    return (dbms_utility.get_time - l_time)/1e2;
    
end execute_statement;



select report_id, duration, round(avg(duration)over(),2) avg_duration, 
    new_duration, round(avg(new_duration)over(),2) avg_new_duration, round(duration/new_duration, 2) fasther_than,
    sum(duration)over() duration_total, sum(new_duration)over() new_duration_total, 
    round(sum(new_duration)over() * 100 / sum(duration)over(), 2) total_improvement_pct,
    sum(duration)over() - sum(new_duration)over() total_improvement
from (
    select 
        report_id, to_number(substr(key4,1,instr(key4,'#')-1)) duration, execute_statement(report_id) new_duration
    from dba_hist_reports where component_name = 'sqlmonitor' and key1 = 'd9vx45z6jq89b' and period_start_time >= date'2023-11-13' --and report_id in (1212241)
    order by to_number(substr(key4,1,instr(key4,'#')-1)) desc
);

/