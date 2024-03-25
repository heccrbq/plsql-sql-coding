select * from dba_hist_sqltext where sql_id = 'd9vx45z6jq89b';
select * from dba_hist_sqlstat where sql_id = 'd9vx45z6jq89b' order by snap_id desc;
select * from dba_hist_snapshot order by begin_interval_time desc;
20947 502 029; 515 exec
select 20947502029/515/1e6 from dual;

SELECT /*+ leading(u ti t d) index(ti icontractitem_no) index(d idocuments_Opdate) */
    SUM(t.value)
FROM
         ubrr_contract_cess u
    JOIN tcontractitem ti ON ( ti.branch = u.branch
                               AND ti.no = u.contractno )
    JOIN tentry        t ON ( t.branch = ti.branch
                       AND t.creditaccount = ti.key )
    JOIN tdocument     d ON ( d.branch = t.branch
                          AND d.docno = t.docno )
WHERE
        1 = 1
    AND u.branch = :b6
    AND u.cessnumber = :b5
    AND u.enddate = TO_DATE('01.01.4000', 'dd.mm.yyyy')
    AND d.opdate = :b4
    AND d.docno >= :b3
    AND t.debitaccount LIKE :b2 || '%'
    AND t.creditaccount LIKE :b1 || '%';
    
    
select * from table(dbms_xplan.display_awr('d9vx45z6jq89b'));


SQL_ID d9vx45z6jq89b
--------------------
SELECT /*+ leading(u ti t d) index(ti icontractitem_no) index(d 
idocuments_Opdate) */ SUM(T.VALUE) FROM UBRR_CONTRACT_CESS U JOIN 
TCONTRACTITEM TI ON ( TI.BRANCH = U.BRANCH AND TI.NO = U.CONTRACTNO ) 
JOIN TENTRY T ON ( T.BRANCH = TI.BRANCH AND T.CREDITACCOUNT = TI.KEY ) 
JOIN TDOCUMENT D ON ( D.BRANCH = T.BRANCH AND D.DOCNO = T.DOCNO ) WHERE 
1=1 AND U.BRANCH = :B6 AND U.CESSNUMBER = :B5 AND U.ENDDATE = 
TO_DATE('01.01.4000', 'dd.mm.yyyy') AND D.OPDATE = :B4 AND D.DOCNO >= 
:B3 AND T.DEBITACCOUNT LIKE :B2 || '%' AND T.CREDITACCOUNT LIKE :B1 || 
'%'
 
Plan hash value: 3187855547
 
--------------------------------------------------------------------------------------------------------------
| Id  | Operation                         | Name                     | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                  |                          |       |       |  3465 (100)|          |
|   1 |  SORT AGGREGATE                   |                          |     1 |   147 |            |          |
|   2 |   NESTED LOOPS                    |                          |       |       |            |          |
|   3 |    NESTED LOOPS                   |                          |     1 |   147 |  3465   (1)| 00:00:01 |
|   4 |     HASH JOIN                     |                          |     1 |   129 |  1352   (1)| 00:00:01 |
|   5 |      TABLE ACCESS BY INDEX ROWID  | TENTRY                   |     1 |    56 |     5   (0)| 00:00:01 |
|   6 |       INDEX RANGE SCAN            | IENTRY_CREDITACCOUNT     |     1 |       |     4   (0)| 00:00:01 |
|   7 |      NESTED LOOPS                 |                          |       |       |            |          |
|   8 |       NESTED LOOPS                |                          |   283 | 20659 |  1347   (1)| 00:00:01 |
|   9 |        TABLE ACCESS BY INDEX ROWID| UBRR_CONTRACT_CESS       |   268 |  8844 |     6   (0)| 00:00:01 |
|  10 |         INDEX RANGE SCAN          | I_UBRR_CONTRACT_CESS_NUM |   506 |       |     3   (0)| 00:00:01 |
|  11 |        INDEX RANGE SCAN           | ICONTRACTITEM_NO         |     5 |       |     2   (0)| 00:00:01 |
|  12 |       TABLE ACCESS BY INDEX ROWID | TCONTRACTITEM            |     1 |    40 |     5   (0)| 00:00:01 |
|  13 |     INDEX RANGE SCAN              | IDOCUMENTS_OPDATE        |   260K|       |   409   (1)| 00:00:01 |
|  14 |    TABLE ACCESS BY INDEX ROWID    | TDOCUMENT                |     1 |    18 |  2113   (1)| 00:00:01 |
--------------------------------------------------------------------------------------------------------------
 
 /
 -- key1 as sql_id
 -- key2 as sql_exec_id
 -- key3 as sql_exec_start
 -- key4 as duration # elapsed_time # cpu_time # disk_reads # read_bytes
 select * from dba_hist_reports where component_name = 'sqlmonitor' and key1 = 'd9vx45z6jq89b' order by generation_time desc;
 select * from dba_hist_reports_details where report_id = 1191304;
<duration>38</duration>
<module>ВУЗ банк. Реестр ежедневных проводок(Ц231)</module>
<action>ubrr_cess_vuz_report_dtrn</action>
<plsql_entry_object_id>4467976</plsql_entry_object_id><plsql_entry_subprogram_id>4</plsql_entry_subprogram_id><plsql_entry_name>A4M.UBRR_CESS_VUZ_REPORT.GETSUM_BKS</plsql_entry_name>
<stat name="buffer_gets">125609</stat><stat name="disk_reads">10183</stat>
38#37984597#1965715#10183#166838272

select * From dba_dependencies where referenced_name = 'DBA_HIST_REPORTS_DETAILS';

1191151 -- 213
1191115 -- 5

SELECT dbms_auto_report.Report_repository_detail(rid=>1191115, TYPE=>'html') FROM dual;



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
    l_result number; -- 
    l_sql varchar2(4000) := q'[
SELECT -- run8
/*+gather_plan_statistics*/
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
    from dba_hist_reports where component_name = 'sqlmonitor' and key1 = 'd9vx45z6jq89b' and period_start_time >= date'2023-11-13' and report_id in (1212075)
--    order by to_number(substr(key4,1,instr(key4,'#')-1)) desc
);
/





-- <report db_version="19.0.0.0.0" elapsed_time="1.60" cpu_time="0.72" cpu_cores="26" hyperthread="Y" timezone_offset="18000" packs="2" service_type="0"><report_id><![CDATA[/orarep/sqlmonitor/main%3finst_id%3d1%26session_id%3d9941%26session_serial%3d12507%26sql_exec_id%3d16777677%26sql_exec_start%3d11%3a10%3a2023%2007%3a13%3a48%26sql_id%3dd9vx45z6jq89b]]></report_id><sql_monitor_report version="4.0" sysdate="11/10/2023 07:14:26"><report_parameters><sql_id>d9vx45z6jq89b</sql_id><sql_exec_id>16777677</sql_exec_id><session_id>9941</session_id><session_serial>12507</session_serial><sql_exec_start>11/10/2023 07:13:48</sql_exec_start><bucket_count>40</bucket_count><interval_start>11/10/2023 07:13:48</interval_start><interval_end>11/10/2023 07:14:27</interval_end></report_parameters><target instance_id="1" session_id="9941" session_serial="12507" sql_id="d9vx45z6jq89b" sql_exec_start="11/10/2023 07:13:48" sql_exec_id="16777677" sql_plan_hash="3187855547" sql_full_plan_hash="1309559160" db_unique_name="XB00" db_platform_name="IBM AIX64/RS6000 V4 - 8.1.0" report_host_name="bdbp00"><user_id>9722</user_id><user>ROBOT_TWR</user><program>oracle@bdbp05 (TNS V1-V3)</program><module>ВУЗ банк. Реестр ежедневных проводок(Ц231)</module><action>ubrr_cess_vuz_report_dtrn</action><service>SYS$USERS</service><plsql_entry_object_id>4467976</plsql_entry_object_id><plsql_entry_subprogram_id>4</plsql_entry_subprogram_id><plsql_entry_name>A4M.UBRR_CESS_VUZ_REPORT.GETSUM_BKS</plsql_entry_name><plsql_object_id>4467976</plsql_object_id><plsql_subprogram_id>4</plsql_subprogram_id><plsql_name>A4M.UBRR_CESS_VUZ_REPORT.GETSUM_BKS</plsql_name><sql_fulltext is_full="Y">SELECT /*+ leading(u ti t d) index(ti icontractitem_no) index(d idocuments_Opdate) */ SUM(T.VALUE) FROM UBRR_CONTRACT_CESS U JOIN TCONTRACTITEM TI ON ( TI.BRANCH = U.BRANCH AND TI.NO = U.CONTRACTNO ) JOIN TENTRY T ON ( T.BRANCH = TI.BRANCH AND T.CREDITACCOUNT = TI.KEY ) JOIN TDOCUMENT D ON ( D.BRANCH = T.BRANCH AND D.DOCNO = T.DOCNO ) WHERE 1=1 AND U.BRANCH = :B6 AND U.CESSNUMBER = :B5 AND U.ENDDATE = TO_DATE(&apos;01.01.4000&apos;, &apos;dd.mm.yyyy&apos;) AND D.OPDATE = :B4 AND D.DOCNO &gt;= :B3 AND T.DEBITACCOUNT LIKE :B2 || &apos;%&apos; AND T.CREDITACCOUNT LIKE :B1 || &apos;%&apos;</sql_fulltext><status>DONE (ALL ROWS)</status><refresh_count>19</refresh_count><first_refresh_time>11/10/2023 07:13:54</first_refresh_time><last_refresh_time>11/10/2023 07:14:26</last_refresh_time><duration>38</duration><optimizer_env><param name="_pga_max_size">2097152 KB</param><param name="active_instance_count">1</param><param name="db_file_multiblock_read_count">64</param><param name="hash_area_size">65535000</param><param name="is_recur_flags">1</param><param name="optimizer_adaptive_plans">false</param><param name="optimizer_adaptive_reporting_only">true</param><param name="optimizer_features_enable">11.2.0.4</param><param name="optimizer_features_hinted">11.2.0.4</param><param name="optimizer_mode_hinted">true</param><param name="parallel_autodop">0</param><param name="parallel_ddl_mode">enabled</param><param name="parallel_ddldml">0</param><param name="parallel_degree">0</param><param name="parallel_execution_enabled">false</param><param name="parallel_max_degree">208</param><param name="parallel_query_default_dop">0</param><param name="parallel_query_mode">enabled</param><param name="pga_aggregate_target">134217728 KB</param><param name="sort_area_size">32768000</param><param name="star_transformation_enabled">true</param><param name="total_cpu_count">208</param></optimizer_env></target><stats type="monitor"><stat name="elapsed_time">37984597</stat><stat name="cpu_time">1965715</stat><stat name="user_io_wait_time">33847669</stat><stat name="concurrency_wait_time">34620</stat><stat name="other_wait_time">2136593</stat><stat name="user_fetch_count">1</stat><stat name="buffer_gets">125609</stat><stat name="disk_reads">10183</stat><stat name="read_reqs">10183</stat><stat name="read_bytes">166838272</stat></stats><activity_sampled><activity class="Concurrency" event="latch: cache buffers chains">1</activity><activity class="Cpu">5</activity><activity class="Other SQL Execution" event="sql_id: 3dcq28hwrkytp">1</activity><activity class="User I/O" event="db file sequential read">8</activity><activity class="User I/O" event="read by other session">23</activity></activity_sampled>
<binds><bind name=":B6" pos="1" dty="2" dtystr="NUMBER" maxlen="22" len="2">1</bind><bind name=":B5" pos="2" dty="2" dtystr="NUMBER" maxlen="22" len="3">231</bind><bind name=":B4" pos="3" dty="12" dtystr="DATE" maxlen="7" len="7">11/09/2023 00:00:00</bind><bind name=":B3" pos="4" dty="2" dtystr="NUMBER" maxlen="22" len="6">5779298815</bind><bind name=":B2" pos="5" dty="1" dtystr="VARCHAR2(32)" maxlen="32" csid="152" len="5">61209</bind><bind name=":B1" pos="6" dty="1" dtystr="VARCHAR2(32)" maxlen="32" csid="152" len="5">47427</bind></binds>
<activity_detail start_time="11/10/2023 07:13:48" end_time="11/10/2023 07:14:27" first_sample_time="11/10/2023 07:13:49" last_sample_time="11/10/2023 07:14:26" duration="38" sample_interval="1" bucket_interval="1" bucket_count="40" bucket_duration="40" cpu_cores="26" total_cpu_cores="26" hyperthread="Y"><bucket number="2"><activity class="Cpu" line="6">1</activity></bucket><bucket number="3"><activity class="Cpu" line="6">1</activity></bucket><bucket number="4"><activity class="Cpu" line="6">1</activity></bucket><bucket number="5"><activity class="User I/O" event="db file sequential read" line="6">1</activity></bucket><bucket number="6"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="7"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="8"><activity class="User I/O" event="db file sequential read" line="6">1</activity></bucket><bucket number="9"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="10"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="11"><activity class="User I/O" event="db file sequential read" line="6">1</activity></bucket><bucket number="12"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="13"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="14"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="15"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="16"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="17"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="18"><activity class="User I/O" event="db file sequential read" line="6">1</activity></bucket><bucket number="19"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="20"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="21"><activity class="User I/O" event="db file sequential read" line="6">1</activity></bucket><bucket number="22"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="23"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="24"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="25"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="26"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="27"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="28"><activity class="Cpu" line="6">1</activity></bucket><bucket number="29"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="30"><activity class="User I/O" event="db file sequential read" line="6">1</activity></bucket><bucket number="31"><activity class="User I/O" event="db file sequential read" line="6">1</activity></bucket><bucket number="32"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="33"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="34"><activity class="Concurrency" event="latch: cache buffers chains" line="6">1</activity></bucket><bucket number="35"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="36"><activity class="User I/O" event="db file sequential read" line="6">1</activity></bucket><bucket number="37"><activity class="User I/O" event="read by other session" line="6">1</activity></bucket><bucket number="38"><activity class="Cpu" line="6">1</activity></bucket><bucket number="39"><activity sql="3dcq28hwrkytp" other_sql_class="User I/O">1</activity></bucket></activity_detail><plan><operation name="SELECT STATEMENT" id="0" depth="0" pos="17852"><cost>17852</cost></operation><operation name="SORT" options="AGGREGATE" id="1" depth="1" pos="1"><card>1</card><bytes>147</bytes><qblock>SEL$EE94F965</qblock><other_xml><info type="has_user_tab">yes</info><info type="db_version">19.0.0.0</info><info type="parse_schema"><![CDATA["A4M"]]></info><info type="plan_hash_full">1309559160</info><info type="plan_hash">3187855547</info><info type="plan_hash_2">1309559160</info>
<peeked_binds><bind nam=":B6" pos="1" dty="2" pre="0" scl="0" mxl="22">c102</bind><bind nam=":B5" pos="2" dty="2" pre="0" scl="0" mxl="22">c13e</bind><bind nam=":B4" pos="3" dty="12" mxl="7">787b0b09010101</bind><bind nam=":B3" pos="4" dty="2" pre="0" scl="0" mxl="22">c53a501e5910</bind><bind nam=":B2" pos="5" dty="1" csi="152" frm="1" mxl="32">3631323039</bind><bind nam=":B1" pos="6" dty="1" csi="152" frm="1" mxl="32">3435393135</bind></peeked_binds>

<stats type="compilation"><stat name="bg">18</stat></stats><qb_registry><q o="2"><n><![CDATA[SEL$4]]></n><f><h><t><![CDATA[from$_subquery$_007]]></t><s><![CDATA[SEL$4]]></s></h></f></q><q o="18" h="y"><n><![CDATA[SEL$9E43CB6E]]></n><p><![CDATA[SEL$3]]></p><i><o><t>VW</t><v><![CDATA[SEL$58A6D7F6]]></v></o></i><f><h><t><![CDATA[TI]]></t><s><![CDATA[SEL$1]]></s></h><h><t><![CDATA[U]]></t><s><![CDATA[SEL$1]]></s></h><h><t><![CDATA[T]]></t><s><![CDATA[SEL$2]]></s></h><h><t><![CDATA[D]]></t><s><![CDATA[SEL$3]]></s></h></f></q><q o="2"><n><![CDATA[SEL$1]]></n><f><h><t><![CDATA[TI]]></t><s><![CDATA[SEL$1]]></s></h><h><t><![CDATA[U]]></t><s><![CDATA[SEL$1]]></s></h></f></q><q o="18" h="y"><n><![CDATA[SEL$58A6D7F6]]></n><p><![CDATA[SEL$2]]></p><i><o><t>VW</t><v><![CDATA[SEL$1]]></v></o></i><f><h><t><![CDATA[TI]]></t><s><![CDATA[SEL$1]]></s></h><h><t><![CDATA[U]]></t><s><![CDATA[SEL$1]]></s></h><h><t><![CDATA[T]]></t><s><![CDATA[SEL$2]]></s></h></f></q><q o="2"><n><![CDATA[SEL$2]]></n><f><h><t><![CDATA[T]]></t><s><![CDATA[SEL$2]]></s></h><h><t><![CDATA[from$_subquery$_003]]></t><s><![CDATA[SEL$2]]></s></h></f></q><q o="2"><n><![CDATA[SEL$3]]></n><f><h><t><![CDATA[D]]></t><s><![CDATA[SEL$3]]></s></h><h><t><![CDATA[from$_subquery$_005]]></t><s><![CDATA[SEL$3]]></s></h></f></q><q o="18" f="y" h="y"><n><![CDATA[SEL$EE94F965]]></n><p><![CDATA[SEL$4]]></p><i><o><t>VW</t><v><![CDATA[SEL$9E43CB6E]]></v></o></i><f><h><t><![CDATA[TI]]></t><s><![CDATA[SEL$1]]></s></h><h><t><![CDATA[U]]></t><s><![CDATA[SEL$1]]></s></h><h><t><![CDATA[T]]></t><s><![CDATA[SEL$2]]></s></h><h><t><![CDATA[D]]></t><s><![CDATA[SEL$3]]></s></h></f></q></qb_registry><outline_data><hint><![CDATA[IGNORE_OPTIM_EMBEDDED_HINTS]]></hint><hint><![CDATA[OPTIMIZER_FEATURES_ENABLE('11.2.0.4')]]></hint><hint><![CDATA[DB_VERSION('19.1.0')]]></hint><hint><![CDATA[OPT_PARAM('_optimizer_control_shard_qry_processing' 65535)]]></hint><hint><![CDATA[OPT_PARAM('star_transformation_enabled' 'true')]]></hint><hint><![CDATA[ALL_ROWS]]></hint><hint><![CDATA[OUTLINE_LEAF(@"SEL$EE94F965")]]></hint><hint><![CDATA[MERGE(@"SEL$9E43CB6E" >"SEL$4")]]></hint><hint><![CDATA[OUTLINE(@"SEL$4")]]></hint><hint><![CDATA[OUTLINE(@"SEL$9E43CB6E")]]></hint><hint><![CDATA[MERGE(@"SEL$58A6D7F6" >"SEL$3")]]></hint><hint><![CDATA[OUTLINE(@"SEL$3")]]></hint><hint><![CDATA[OUTLINE(@"SEL$58A6D7F6")]]></hint><hint><![CDATA[MERGE(@"SEL$1" >"SEL$2")]]></hint><hint><![CDATA[OUTLINE(@"SEL$2")]]></hint><hint><![CDATA[OUTLINE(@"SEL$1")]]></hint><hint><![CDATA[INDEX_RS_ASC(@"SEL$EE94F965" "U"@"SEL$1" ("UBRR_CONTRACT_CESS"."CESSNUMBER"))]]></hint><hint><![CDATA[INDEX(@"SEL$EE94F965" "TI"@"SEL$1" ("TCONTRACTITEM"."BRANCH" "TCONTRACTITEM"."NO" "TCONTRACTITEM"."ITEMCODE"))]]></hint><hint><![CDATA[INDEX_RS_ASC(@"SEL$EE94F965" "T"@"SEL$2" ("TENTRY"."BRANCH" "TENTRY"."CREDITACCOUNT" "TENTRY"."DOCNO"))]]></hint><hint><![CDATA[INDEX(@"SEL$EE94F965" "D"@"SEL$3" ("TDOCUMENT"."BRANCH" "TDOCUMENT"."OPDATE" "TDOCUMENT"."NEWDOCNO"))]]></hint><hint><![CDATA[LEADING(@"SEL$EE94F965" "U"@"SEL$1" "TI"@"SEL$1" "T"@"SEL$2" "D"@"SEL$3")]]></hint><hint><![CDATA[USE_NL(@"SEL$EE94F965" "TI"@"SEL$1")]]></hint><hint><![CDATA[NLJ_BATCHING(@"SEL$EE94F965" "TI"@"SEL$1")]]></hint><hint><![CDATA[USE_HASH(@"SEL$EE94F965" "T"@"SEL$2")]]></hint><hint><![CDATA[USE_NL(@"SEL$EE94F965" "D"@"SEL$3")]]></hint><hint><![CDATA[NLJ_BATCHING(@"SEL$EE94F965" "D"@"SEL$3")]]></hint><hint><![CDATA[SWAP_JOIN_INPUTS(@"SEL$EE94F965" "T"@"SEL$2")]]></hint></outline_data><hint_usage><q><n><![CDATA[SEL$EE94F965]]></n><m><h o="OU"><x><![CDATA[LEADING(@"SEL$EE94F965" "U"@"SEL$1" "TI"@"SEL$1" "T"@"SEL$2" "D"@"SEL$3")]]></x></h><h o="EM" st="NU"><x><![CDATA[leading(u ti t d)]]></x><r><![CDATA[rejected by IGNORE_OPTIM_EMBEDDED_HINTS]]></r></h></m><t><f><![CDATA["D"@"SEL$3"]]></f><h o="OU"><x><![CDATA[NLJ_BATCHING(@"SEL$EE94F965" "D"@"SEL$3")]]></x></h><h o="OU"><x><![CDATA[USE_NL(@"SEL$EE94F965" "D"@"SEL$3")]]></x></h><h o="OU"><x><![CDATA[INDEX(@"SEL$EE94F965" "D"@"SEL$3" ("TDOCUMENT"."BRANCH" "TDOCUMENT"."OPDATE" "TDOCUMENT"."NEWDOCNO"))]]></x></h><h o="EM" st="NU"><x><![CDATA[index(d idocuments_Opdate)]]></x><r><![CDATA[rejected by IGNORE_OPTIM_EMBEDDED_HINTS]]></r></h></t><t><f><![CDATA["T"@"SEL$2"]]></f><h o="OU"><x><![CDATA[SWAP_JOIN_INPUTS(@"SEL$EE94F965" "T"@"SEL$2")]]></x></h><h o="OU"><x><![CDATA[USE_HASH(@"SEL$EE94F965" "T"@"SEL$2")]]></x></h><h o="OU"><x><![CDATA[INDEX_RS_ASC(@"SEL$EE94F965" "T"@"SEL$2" ("TENTRY"."BRANCH" "TENTRY"."CREDITACCOUNT" "TENTRY"."DOCNO"))]]></x></h></t><t><f><![CDATA["TI"@"SEL$1"]]></f><h o="OU"><x><![CDATA[NLJ_BATCHING(@"SEL$EE94F965" "TI"@"SEL$1")]]></x></h><h o="OU"><x><![CDATA[USE_NL(@"SEL$EE94F965" "TI"@"SEL$1")]]></x></h><h o="OU"><x><![CDATA[INDEX(@"SEL$EE94F965" "TI"@"SEL$1" ("TCONTRACTITEM"."BRANCH" "TCONTRACTITEM"."NO" "TCONTRACTITEM"."ITEMCODE"))]]></x></h><h o="EM" st="NU"><x><![CDATA[index(ti icontractitem_no)]]></x><r><![CDATA[rejected by IGNORE_OPTIM_EMBEDDED_HINTS]]></r></h></t><t><f><![CDATA["U"@"SEL$1"]]></f><h o="OU"><x><![CDATA[INDEX_RS_ASC(@"SEL$EE94F965" "U"@"SEL$1" ("UBRR_CONTRACT_CESS"."CESSNUMBER"))]]></x></h></t></q><q><n><![CDATA[SEL$9E43CB6E]]></n><h o="OU"><x><![CDATA[MERGE(@"SEL$9E43CB6E" >"SEL$4")]]></x></h></q><q><n><![CDATA[SEL$58A6D7F6]]></n><h o="OU"><x><![CDATA[MERGE(@"SEL$58A6D7F6" >"SEL$3")]]></x></h></q><q><n><![CDATA[SEL$1]]></n><h o="OU"><x><![CDATA[MERGE(@"SEL$1" >"SEL$2")]]></x></h></q><s><h o="OU"><x><![CDATA[ALL_ROWS]]></x></h><h o="OU"><x><![CDATA[OPT_PARAM('star_transformation_enabled' 'true')]]></x></h><h o="OU"><x><![CDATA[OPT_PARAM('_optimizer_control_shard_qry_processing' 65535)]]></x></h><h o="OU"><x><![CDATA[DB_VERSION('19.1.0')]]></x></h><h o="OU"><x><![CDATA[OPTIMIZER_FEATURES_ENABLE('11.2.0.4')]]></x></h><h o="OU"><x><![CDATA[IGNORE_OPTIM_EMBEDDED_HINTS]]></x></h></s></hint_usage></other_xml><hreport><leg><t>3</t><u>3</u></leg><sec id="1"><n><![CDATA[SEL$EE94F965]]></n><h st="U"><![CDATA[leading(u ti t d) / rejected by IGNORE_OPTIM_EMBEDDED_HINTS]]></h></sec><sec id="11"><n><![CDATA[SEL$EE94F965 / TI@SEL$1]]></n><h st="U"><![CDATA[index(ti icontractitem_no) / rejected by IGNORE_OPTIM_EMBEDDED_HINTS]]></h></sec><sec id="13"><n><![CDATA[SEL$EE94F965 / D@SEL$3]]></n><h st="U"><![CDATA[index(d idocuments_Opdate) / rejected by IGNORE_OPTIM_EMBEDDED_HINTS]]></h></sec></hreport></operation><operation name="NESTED LOOPS" id="2" depth="2" pos="1"/><operation name="NESTED LOOPS" id="3" depth="3" pos="1"><card>1</card><bytes>147</bytes><cost>17852</cost><io_cost>17838</io_cost><cpu_cost>301736440</cpu_cost><time>00:00:02 </time></operation><operation name="HASH JOIN" id="4" depth="4" pos="1"><card>1</card><bytes>129</bytes><cost>15827</cost><io_cost>15819</io_cost><cpu_cost>171491771</cpu_cost><time>00:00:02 </time><predicates type="access">&quot;T&quot;.&quot;BRANCH&quot;=&quot;TI&quot;.&quot;BRANCH&quot; AND &quot;T&quot;.&quot;CREDITACCOUNT&quot;=&quot;TI&quot;.&quot;KEY&quot;</predicates></operation><operation name="TABLE ACCESS" options="BY INDEX ROWID" id="5" depth="5" pos="1"><object>TENTRY</object><card>1</card><bytes>56</bytes><cost>5</cost><io_cost>5</io_cost><cpu_cost>88624</cpu_cost><time>00:00:01 </time><predicates type="filter">&quot;T&quot;.&quot;DEBITACCOUNT&quot; LIKE :B2||&apos;%&apos;</predicates><qblock>SEL$EE94F965</qblock><object_alias>&quot;T&quot;@&quot;SEL$2&quot;</object_alias></operation><operation name="INDEX" options="RANGE SCAN" id="6" depth="6" pos="1"><object>IENTRY_CREDITACCOUNT</object><card>1</card><cost>4</cost><io_cost>4</io_cost><cpu_cost>78572</cpu_cost><time>00:00:01 </time><predicates type="access">&quot;T&quot;.&quot;BRANCH&quot;=:B6 AND &quot;T&quot;.&quot;CREDITACCOUNT&quot; LIKE :B1||&apos;%&apos; AND &quot;T&quot;.&quot;DOCNO&quot;&gt;=:B3</predicates><predicates type="filter">(&quot;T&quot;.&quot;DOCNO&quot;&gt;=:B3 AND &quot;T&quot;.&quot;CREDITACCOUNT&quot; LIKE :B1||&apos;%&apos;)</predicates><qblock>SEL$EE94F965</qblock><object_alias>&quot;T&quot;@&quot;SEL$2&quot;</object_alias></operation><operation name="NESTED LOOPS" id="7" depth="5" pos="2"/><operation name="NESTED LOOPS" id="8" depth="6" pos="1"><card>2219</card><bytes>161987</bytes><cost>15822</cost><io_cost>15814</io_cost><cpu_cost>170481096</cpu_cost><time>00:00:02 </time></operation><operation name="TABLE ACCESS" options="BY INDEX ROWID" id="9" depth="7" pos="1"><object>UBRR_CONTRACT_CESS</object><card>1973</card><bytes>65109</bytes><cost>30</cost><io_cost>30</io_cost><cpu_cost>2621525</cpu_cost><time>00:00:01 </time><predicates type="filter">(&quot;U&quot;.&quot;ENDDATE&quot;=TO_DATE(&apos; 4000-01-01 00:00:00&apos;, &apos;syyyy-mm-dd hh24:mi:ss&apos;) AND &quot;U&quot;.&quot;BRANCH&quot;=:B6)</predicates><qblock>SEL$EE94F965</qblock><object_alias>&quot;U&quot;@&quot;SEL$1&quot;</object_alias></operation><operation name="INDEX" options="RANGE SCAN" id="10" depth="8" pos="1"><object>I_UBRR_CONTRACT_CESS_NUM</object><card>3721</card><cost>8</cost><io_cost>8</io_cost><cpu_cost>820143</cpu_cost><time>00:00:01 </time><predicates type="access">&quot;U&quot;.&quot;CESSNUMBER&quot;=:B5</predicates><qblock>SEL$EE94F965</qblock><object_alias>&quot;U&quot;@&quot;SEL$1&quot;</object_alias></operation><operation name="INDEX" options="RANGE SCAN" id="11" depth="7" pos="2"><object>ICONTRACTITEM_NO</object><card>10</card><cost>2</cost><io_cost>2</io_cost><cpu_cost>22336</cpu_cost><time>00:00:01 </time><predicates type="access">&quot;TI&quot;.&quot;BRANCH&quot;=:B6 AND &quot;TI&quot;.&quot;NO&quot;=&quot;U&quot;.&quot;CONTRACTNO&quot;</predicates><qblock>SEL$EE94F965</qblock><object_alias>&quot;TI&quot;@&quot;SEL$1&quot;</object_alias></operation><operation name="TABLE ACCESS" options="BY INDEX ROWID" id="12" depth="6" pos="2"><object>TCONTRACTITEM</object><card>1</card><bytes>40</bytes><cost>8</cost><io_cost>8</io_cost><cpu_cost>85078</cpu_cost><time>00:00:01 </time><predicates type="filter">&quot;TI&quot;.&quot;KEY&quot; LIKE :B1||&apos;%&apos;</predicates><qblock>SEL$EE94F965</qblock><object_alias>&quot;TI&quot;@&quot;SEL$1&quot;</object_alias></operation><operation name="INDEX" options="RANGE SCAN" id="13" depth="4" pos="2"><object>IDOCUMENTS_OPDATE</object><card>241547</card><cost>438</cost><io_cost>436</io_cost><cpu_cost>52323946</cpu_cost><time>00:00:01 </time><predicates type="access">&quot;D&quot;.&quot;BRANCH&quot;=:B6 AND &quot;D&quot;.&quot;OPDATE&quot;=:B4</predicates><qblock>SEL$EE94F965</qblock><object_alias>&quot;D&quot;@&quot;SEL$3&quot;</object_alias></operation><operation name="TABLE ACCESS" options="BY INDEX ROWID" id="14" depth="3" pos="2"><object>TDOCUMENT</object><card>1</card><bytes>18</bytes><cost>2025</cost><io_cost>2019</io_cost><cpu_cost>130244669</cpu_cost><time>00:00:01 </time><predicates type="filter">(&quot;D&quot;.&quot;DOCNO&quot;&gt;=:B3 AND &quot;D&quot;.&quot;DOCNO&quot;=&quot;T&quot;.&quot;DOCNO&quot;)</predicates><qblock>SEL$EE94F965</qblock><object_alias>&quot;D&quot;@&quot;SEL$3&quot;</object_alias></operation></plan><plan_monitor max_activity_count="37" max_io_reqs="8933" max_io_bytes="146358272" max_imq_count="0" max_cpu_count="5" max_wait_count="32" max_other_sql_count="0"><operation id="0" name="SELECT STATEMENT" depth="0" position="0" skp="0"><stats type="plan_monitor"><stat name="first_active">11/10/2023 07:14:26</stat><stat name="last_active">11/10/2023 07:14:26</stat><stat name="duration">1</stat><stat name="from_most_recent">0</stat><stat name="from_sql_exec_start">38</stat><stat name="starts">1</stat><stat name="cardinality">1</stat></stats></operation><operation id="1" parent_id="0" name="SORT" options="AGGREGATE" depth="1" position="1" skp="0"><optimizer><cardinality>1</cardinality><bytes>147</bytes></optimizer><stats type="plan_monitor"><stat name="first_active">11/10/2023 07:14:26</stat><stat name="last_active">11/10/2023 07:14:26</stat><stat name="duration">1</stat><stat name="from_most_recent">0</stat><stat name="from_sql_exec_start">38</stat><stat name="starts">1</stat><stat name="cardinality">1</stat></stats><rwsstats group_id="20"><metadata><stat id="1" name="Total Number of Rowsets" desc="Total number of rowsets received from underlying input" type="1"/><stat id="2" name="Rowsets with Encodings" desc="Number of rowsets with encodings" type="1"/><stat id="3" name="Rowsets Leveraging Encodings" desc="Number of rowsets leveraging encodings" type="1"/><stat id="4" name="Rowsets Leveraging Storage Aggregation" desc="Number of rowsets leveraging storage aggregation pushdown" type="1"/></metadata></rwsstats></operation><operation id="2" parent_id="1" name="NESTED LOOPS" depth="2" position="1" skp="0"><stats type="plan_monitor"><stat name="starts">1</stat></stats></operation><operation id="3" parent_id="2" name="NESTED LOOPS" depth="3" position="1" skp="0"><optimizer><cardinality>1</cardinality><bytes>147</bytes><cost>17852</cost><cpu_cost>301736440</cpu_cost><io_cost>17838</io_cost><time>2</time></optimizer><stats type="plan_monitor"><stat name="starts">1</stat></stats></operation><operation id="4" parent_id="3" name="HASH JOIN" depth="4" position="1" skp="0"><optimizer><cardinality>1</cardinality><bytes>129</bytes><cost>15827</cost><cpu_cost>171491771</cpu_cost><io_cost>15819</io_cost><time>2</time></optimizer><stats type="plan_monitor"><stat name="first_active">11/10/2023 07:13:54</stat><stat name="last_active">11/10/2023 07:14:26</stat><stat name="duration">33</stat><stat name="from_most_recent">0</stat><stat name="from_sql_exec_start">6</stat><stat name="starts">1</stat><stat name="cardinality">0</stat><stat name="max_memory">631808</stat></stats><rwsstats group_id="0"><metadata><stat id="1" name="Build Size" desc="Size of the build input in bytes" type="4" flags="1"/><stat id="2" name="Build Row Count" desc="Number of rows for the build" type="5"/><stat id="3" name="Fan-out" desc="Number of partitions used to split both inputs" type="5"/><stat id="4" name="Slot Size" desc="Size of an in-memory hash-join slot" type="5"/><stat id="5" name="Total Build Partitions" desc="Total number of build partitions" type="1"/><stat id="6" name="Total Cached Partitions" desc="Total number of build partitions left in-memory before probing" type="1"/><stat id="7" name="Multi-pass Partition Pairs" desc="Total number of partition pairs processed multi-pass" type="1"/><stat id="8" name="Total Spilled Probe Rows" desc="Total number of rows from the probe spilled to disk (excluding buffering)" type="1"/><stat id="9" name="Columnar Encodings Leveraged" desc="Total number of encodings leveraged for probing during probe phase" type="1"/><stat id="10" name="Columnar Encodings Observed" desc="Total number of encodings observed during probe phase" type="1"/></metadata><stat id="1">229376</stat><stat id="2">4</stat><stat id="3">8</stat><stat id="4">114688</stat><stat id="5">8</stat><stat id="6">8</stat></rwsstats></operation><operation id="5" parent_id="4" name="TABLE ACCESS" options="BY INDEX ROWID" depth="5" position="1" skp="0"><object type="TABLE"><owner>A4M</owner><name>TENTRY</name></object><optimizer><cardinality>1</cardinality><bytes>56</bytes><cost>5</cost><cpu_cost>88624</cpu_cost><io_cost>5</io_cost><time>1</time></optimizer><stats type="plan_monitor"><stat name="first_active">11/10/2023 07:13:54</stat><stat name="last_active">11/10/2023 07:14:26</stat><stat name="duration">33</stat><stat name="from_most_recent">0</stat><stat name="from_sql_exec_start">6</stat><stat name="starts">1</stat><stat name="cardinality">4</stat><stat name="read_reqs">86</stat><stat name="read_bytes">1409024</stat></stats></operation><operation id="6" parent_id="5" name="INDEX" options="RANGE SCAN" depth="6" position="1" skp="0"><object type="INDEX"><owner>A4M</owner><name>IENTRY_CREDITACCOUNT</name></object><optimizer><cardinality>1</cardinality><cost>4</cost><cpu_cost>78572</cpu_cost><io_cost>4</io_cost><time>1</time></optimizer><stats type="plan_monitor"><stat name="first_active">11/10/2023 07:13:49</stat><stat name="first_row">11/10/2023 07:13:54</stat><stat name="last_active">11/10/2023 07:14:26</stat><stat name="duration">38</stat><stat name="from_most_recent">0</stat><stat name="from_sql_exec_start">1</stat><stat name="starts">1</stat><stat name="cardinality">44998</stat><stat name="read_reqs">8933</stat><stat name="read_bytes">146358272</stat></stats><activity_sampled start_time="11/10/2023 07:13:49" end_time="11/10/2023 07:14:25" duration="37" count="37" imq_count="0" wait_count="32" cpu_count="5" other_sql_count="0" cpu_cores="26" hyperthread="Y"><activity class="Concurrency" event="latch: cache buffers chains">1</activity><activity class="Cpu">5</activity><activity class="User I/O" event="db file sequential read">8</activity><activity class="User I/O" event="read by other session">23</activity></activity_sampled></operation><operation id="7" parent_id="4" name="NESTED LOOPS" depth="5" position="2" skp="0"><stats type="plan_monitor"><stat name="first_active">11/10/2023 07:14:26</stat><stat name="last_active">11/10/2023 07:14:26</stat><stat name="duration">1</stat><stat name="from_most_recent">0</stat><stat name="from_sql_exec_start">38</stat><stat name="starts">1</stat><stat name="cardinality">572</stat></stats></operation><operation id="8" parent_id="7" name="NESTED LOOPS" depth="6" position="1" skp="0"><optimizer><cardinality>2219</cardinality><bytes>161987</bytes><cost>15822</cost><cpu_cost>170481096</cpu_cost><io_cost>15814</io_cost><time>2</time></optimizer><stats type="plan_monitor"><stat name="first_active">11/10/2023 07:14:26</stat><stat name="last_active">11/10/2023 07:14:26</stat><stat name="duration">1</stat><stat name="from_most_recent">0</stat><stat name="from_sql_exec_start">38</stat><stat name="starts">1</stat><stat name="cardinality">3669</stat></stats></operation><operation id="9" parent_id="8" name="TABLE ACCESS" options="BY INDEX ROWID" depth="7" position="1" skp="0"><object type="TABLE"><owner>A4M</owner><name>UBRR_CONTRACT_CESS</name></object><optimizer><cardinality>1973</cardinality><bytes>65109</bytes><cost>30</cost><cpu_cost>2621525</cpu_cost><io_cost>30</io_cost><time>1</time></optimizer><stats type="plan_monitor"><stat name="first_active">11/10/2023 07:14:26</stat><stat name="last_active">11/10/2023 07:14:26</stat><stat name="duration">1</stat><stat name="from_most_recent">0</stat><stat name="from_sql_exec_start">38</stat><stat name="starts">1</stat><stat name="cardinality">220</stat><stat name="read_reqs">27</stat><stat name="read_bytes">442368</stat></stats></operation><operation id="10" parent_id="9" name="INDEX" options="RANGE SCAN" depth="8" position="1" skp="0"><object type="INDEX"><owner>A4M</owner><name>I_UBRR_CONTRACT_CESS_NUM</name></object><optimizer><cardinality>3721</cardinality><cost>8</cost><cpu_cost>820143</cpu_cost><io_cost>8</io_cost><time>1</time></optimizer><stats type="plan_monitor"><stat name="first_active">11/10/2023 07:14:26</stat><stat name="last_active">11/10/2023 07:14:26</stat><stat name="duration">1</stat><stat name="from_most_recent">0</stat><stat name="from_sql_exec_start">38</stat><stat name="starts">1</stat><stat name="cardinality">2919</stat><stat name="read_reqs">4</stat><stat name="read_bytes">65536</stat></stats></operation><operation id="11" parent_id="8" name="INDEX" options="RANGE SCAN" depth="7" position="2" skp="0"><object type="INDEX (UNIQUE)"><owner>A4M</owner><name>ICONTRACTITEM_NO</name></object><optimizer><cardinality>10</cardinality><cost>2</cost><cpu_cost>22336</cpu_cost><io_cost>2</io_cost><time>1</time></optimizer><stats type="plan_monitor"><stat name="first_active">11/10/2023 07:14:26</stat><stat name="last_active">11/10/2023 07:14:26</stat><stat name="duration">1</stat><stat name="from_most_recent">0</stat><stat name="from_sql_exec_start">38</stat><stat name="starts">423</stat><stat name="cardinality">3669</stat><stat name="read_reqs">290</stat><stat name="read_bytes">4751360</stat></stats></operation><operation id="12" parent_id="7" name="TABLE ACCESS" options="BY INDEX ROWID" depth="6" position="2" skp="0"><object type="TABLE"><owner>A4M</owner><name>TCONTRACTITEM</name></object><optimizer><cardinality>1</cardinality><bytes>40</bytes><cost>8</cost><cpu_cost>85078</cpu_cost><io_cost>8</io_cost><time>1</time></optimizer><stats type="plan_monitor"><stat name="first_active">11/10/2023 07:14:26</stat><stat name="last_active">11/10/2023 07:14:26</stat><stat name="duration">1</stat><stat name="from_most_recent">0</stat><stat name="from_sql_exec_start">38</stat><stat name="starts">5652</stat><stat name="cardinality">572</stat><stat name="read_reqs">843</stat><stat name="read_bytes">13811712</stat></stats></operation><operation id="13" parent_id="3" name="INDEX" options="RANGE SCAN" depth="4" position="2" skp="0"><object type="INDEX"><owner>A4M</owner><name>IDOCUMENTS_OPDATE</name></object><optimizer><cardinality>241547</cardinality><cost>438</cost><cpu_cost>52323946</cpu_cost><io_cost>436</io_cost><time>1</time></optimizer><stats type="plan_monitor"/></operation><operation id="14" parent_id="2" name="TABLE ACCESS" options="BY INDEX ROWID" depth="3" position="2" skp="0"><object type="TABLE"><owner>A4M</owner><name>TDOCUMENT</name></object><optimizer><cardinality>1</cardinality><bytes>18</bytes><cost>2025</cost><cpu_cost>130244669</cpu_cost><io_cost>2019</io_cost><time>1</time></optimizer><stats type="plan_monitor"/></operation></plan_monitor><stattype name="metrics" cpu_cores="26" hyperthread="Y"><stat_info><stat id="1" name="nb_cpu"/><stat id="2" name="nb_sess"/><stat id="3" name="reads" unit="per_sec"/><stat id="4" name="writes" unit="per_sec"/><stat id="5" name="read_kb" unit="bytes_per_sec" factor="1024"/><stat id="6" name="write_kb" unit="bytes_per_sec" factor="1024"/><stat id="7" name="interc_kb" unit="bytes_per_sec" factor="1024"/><stat id="8" name="cache_kb" unit="bytes_per_sec" factor="1024"/><stat id="9" name="pga_kb" unit="bytes" factor="1024"/><stat id="10" name="tmp_kb" unit="bytes" factor="1024"/></stat_info><buckets bucket_interval="1" bucket_count="40" start_time="11/10/2023 07:13:48" end_time="11/10/2023 07:14:27" duration="40"><bucket bucket_id="1"><stat id="1" value=".12"/><stat id="3" value="1627"/><stat id="5" value="26033"/><stat id="7" value="26033"/><stat id="8" value="346415"/><stat id="9" value="17825"/><stat id="10" value="2049"/></bucket><bucket bucket_id="2"><stat id="1" value=".33"/><stat id="3" value="68"/><stat id="5" value="1092"/><stat id="7" value="1092"/><stat id="8" value="430771"/><stat id="9" value="17811"/><stat id="10" value="2048"/></bucket><bucket bucket_id="3"><stat id="1" value=".25"/><stat id="3" value="104"/><stat id="5" value="1660"/><stat id="7" value="1660"/><stat id="8" value="182497"/><stat id="9" value="17802"/><stat id="10" value="2047"/></bucket><bucket bucket_id="4"><stat id="1" value=".04"/><stat id="3" value="167"/><stat id="5" value="2668"/><stat id="7" value="2668"/><stat id="8" value="35938"/><stat id="9" value="17823"/><stat id="10" value="2049"/></bucket><bucket bucket_id="5"><stat id="1" value=".04"/><stat id="3" value="222"/><stat id="5" value="3556"/><stat id="7" value="3556"/><stat id="8" value="36870"/><stat id="9" value="17812"/><stat id="10" value="2048"/></bucket><bucket bucket_id="6"><stat id="1" value=".04"/><stat id="3" value="155"/><stat id="5" value="2474"/><stat id="7" value="2474"/><stat id="8" value="35405"/><stat id="9" value="17810"/><stat id="10" value="2048"/></bucket><bucket bucket_id="7"><stat id="1" value=".04"/><stat id="3" value="177"/><stat id="5" value="2825"/><stat id="7" value="2825"/><stat id="8" value="35878"/><stat id="9" value="17805"/><stat id="10" value="2047"/></bucket><bucket bucket_id="8"><stat id="1" value=".04"/><stat id="3" value="326"/><stat id="5" value="5221"/><stat id="7" value="5221"/><stat id="8" value="39794"/><stat id="9" value="17828"/><stat id="10" value="2050"/></bucket><bucket bucket_id="9"><stat id="1" value=".04"/><stat id="3" value="303"/><stat id="5" value="4847"/><stat id="7" value="4847"/><stat id="8" value="41126"/><stat id="9" value="17804"/><stat id="10" value="2047"/></bucket><bucket bucket_id="10"><stat id="1" value=".04"/><stat id="3" value="141"/><stat id="5" value="2254"/><stat id="7" value="2254"/><stat id="8" value="36752"/><stat id="9" value="17824"/><stat id="10" value="2049"/></bucket><bucket bucket_id="11"><stat id="1" value=".04"/><stat id="3" value="177"/><stat id="5" value="2829"/><stat id="7" value="2829"/><stat id="8" value="37931"/><stat id="9" value="17810"/><stat id="10" value="2048"/></bucket><bucket bucket_id="12"><stat id="1" value=".04"/><stat id="3" value="380"/><stat id="5" value="6080"/><stat id="7" value="6080"/><stat id="8" value="34901"/><stat id="9" value="17805"/><stat id="10" value="2047"/></bucket><bucket bucket_id="13"><stat id="1" value=".04"/><stat id="3" value="282"/><stat id="5" value="4513"/><stat id="7" value="4513"/><stat id="8" value="36153"/><stat id="9" value="17808"/><stat id="10" value="2047"/></bucket><bucket bucket_id="14"><stat id="1" value=".04"/><stat id="3" value="110"/><stat id="5" value="1761"/><stat id="7" value="1761"/><stat id="8" value="42414"/><stat id="9" value="17825"/><stat id="10" value="2049"/></bucket><bucket bucket_id="15"><stat id="1" value=".04"/><stat id="3" value="145"/><stat id="5" value="2322"/><stat id="7" value="2322"/><stat id="8" value="34964"/><stat id="9" value="17814"/><stat id="10" value="2048"/></bucket><bucket bucket_id="16"><stat id="1" value=".04"/><stat id="3" value="93"/><stat id="5" value="1494"/><stat id="7" value="1494"/><stat id="8" value="39386"/><stat id="9" value="17806"/><stat id="10" value="2047"/></bucket><bucket bucket_id="17"><stat id="1" value=".04"/><stat id="3" value="135"/><stat id="5" value="2153"/><stat id="7" value="2153"/><stat id="8" value="32497"/><stat id="9" value="17823"/><stat id="10" value="2049"/></bucket><bucket bucket_id="18"><stat id="1" value=".04"/><stat id="3" value="379"/><stat id="5" value="6057"/><stat id="7" value="6057"/><stat id="8" value="33599"/><stat id="9" value="17801"/><stat id="10" value="2047"/></bucket><bucket bucket_id="19"><stat id="1" value=".04"/><stat id="3" value="276"/><stat id="5" value="4409"/><stat id="7" value="4409"/><stat id="8" value="43361"/><stat id="9" value="17816"/><stat id="10" value="2048"/></bucket><bucket bucket_id="20"><stat id="1" value=".04"/><stat id="3" value="128"/><stat id="5" value="2045"/><stat id="7" value="2045"/><stat id="8" value="37372"/><stat id="9" value="17807"/><stat id="10" value="2047"/></bucket><bucket bucket_id="21"><stat id="1" value=".04"/><stat id="3" value="223"/><stat id="5" value="3576"/><stat id="7" value="3576"/><stat id="8" value="42197"/><stat id="9" value="17827"/><stat id="10" value="2050"/></bucket><bucket bucket_id="22"><stat id="1" value=".04"/><stat id="3" value="352"/><stat id="5" value="5629"/><stat id="7" value="5629"/><stat id="8" value="30014"/><stat id="9" value="17807"/><stat id="10" value="2047"/></bucket><bucket bucket_id="23"><stat id="1" value=".04"/><stat id="3" value="306"/><stat id="5" value="4890"/><stat id="7" value="4890"/><stat id="8" value="34153"/><stat id="9" value="17818"/><stat id="10" value="2049"/></bucket><bucket bucket_id="24"><stat id="1" value=".04"/><stat id="3" value="374"/><stat id="5" value="5980"/><stat id="7" value="5980"/><stat id="8" value="40563"/><stat id="9" value="17802"/><stat id="10" value="2047"/></bucket><bucket bucket_id="25"><stat id="1" value=".04"/><stat id="3" value="336"/><stat id="5" value="5382"/><stat id="7" value="5382"/><stat id="8" value="37014"/><stat id="9" value="17819"/><stat id="10" value="2049"/></bucket><bucket bucket_id="26"><stat id="1" value=".04"/><stat id="3" value="219"/><stat id="5" value="3499"/><stat id="7" value="3499"/><stat id="8" value="34579"/><stat id="9" value="17812"/><stat id="10" value="2048"/></bucket><bucket bucket_id="27"><stat id="1" value=".04"/><stat id="3" value="151"/><stat id="5" value="2410"/><stat id="7" value="2410"/><stat id="8" value="32016"/><stat id="9" value="17819"/><stat id="10" value="2049"/></bucket><bucket bucket_id="28"><stat id="1" value=".03"/><stat id="3" value="209"/><stat id="5" value="3339"/><stat id="7" value="3339"/><stat id="8" value="31124"/><stat id="9" value="17808"/><stat id="10" value="2047"/></bucket><bucket bucket_id="29"><stat id="1" value=".03"/><stat id="3" value="148"/><stat id="5" value="2366"/><stat id="7" value="2366"/><stat id="8" value="30411"/><stat id="9" value="17804"/><stat id="10" value="2047"/></bucket><bucket bucket_id="30"><stat id="1" value=".04"/><stat id="3" value="371"/><stat id="5" value="5931"/><stat id="7" value="5931"/><stat id="8" value="40668"/><stat id="9" value="17814"/><stat id="10" value="2048"/></bucket><bucket bucket_id="31"><stat id="1" value=".04"/><stat id="3" value="391"/><stat id="5" value="6264"/><stat id="7" value="6264"/><stat id="8" value="33306"/><stat id="9" value="17829"/><stat id="10" value="2050"/></bucket><bucket bucket_id="32"><stat id="1" value=".04"/><stat id="3" value="325"/><stat id="5" value="5193"/><stat id="7" value="5193"/><stat id="8" value="38643"/><stat id="9" value="17800"/><stat id="10" value="2047"/></bucket><bucket bucket_id="33"><stat id="1" value=".04"/><stat id="3" value="312"/><stat id="5" value="4995"/><stat id="7" value="4995"/><stat id="8" value="33380"/><stat id="9" value="17827"/><stat id="10" value="2050"/></bucket><bucket bucket_id="34"><stat id="1" value=".04"/><stat id="3" value="130"/><stat id="5" value="2087"/><stat id="7" value="2087"/><stat id="8" value="32651"/><stat id="9" value="17780"/><stat id="10" value="2044"/></bucket><bucket bucket_id="35"><stat id="1" value=".04"/><stat id="3" value="141"/><stat id="5" value="2248"/><stat id="7" value="2248"/><stat id="8" value="38612"/><stat id="9" value="17839"/><stat id="10" value="2051"/></bucket><bucket bucket_id="36"><stat id="1" value=".04"/><stat id="3" value="126"/><stat id="5" value="2010"/><stat id="7" value="2010"/><stat id="8" value="39271"/><stat id="9" value="17817"/><stat id="10" value="2048"/></bucket><bucket bucket_id="37"><stat id="1" value=".04"/><stat id="3" value="371"/><stat id="5" value="5931"/><stat id="7" value="5931"/><stat id="8" value="35712"/><stat id="9" value="17803"/><stat id="10" value="2047"/></bucket><bucket bucket_id="38"><stat id="1" value=".04"/><stat id="3" value="433"/><stat id="5" value="6921"/><stat id="7" value="6921"/><stat id="8" value="36301"/><stat id="9" value="17817"/><stat id="10" value="2048"/></bucket><bucket bucket_id="39"><stat id="1" value=".04"/><stat id="3" value="2163"/><stat id="5" value="34605"/><stat id="7" value="34605"/><stat id="8" value="199136"/><stat id="9" value="17819"/><stat id="10" value="2049"/></bucket><bucket bucket_id="40"><stat id="1" value=".04"/></bucket></buckets></stattype></sql_monitor_report></report>


<report_repository_summary><sql sql_id="d9vx45z6jq89b" sql_exec_start="11/10/2023 07:13:48" sql_exec_id="16777677"><status>DONE (ALL ROWS)</status><sql_text>SELECT /*+ leading(u ti t d) index(ti icontractitem_no) index(d idocuments_Opdate) */ SUM(T.VALUE) F</sql_text><first_refresh_time>11/10/2023 07:13:54</first_refresh_time><last_refresh_time>11/10/2023 07:14:26</last_refresh_time><refresh_count>19</refresh_count><inst_id>1</inst_id><session_id>9941</session_id><session_serial>12507</session_serial><user_id>9722</user_id><user>ROBOT_TWR</user><module>ВУЗ банк. Реестр ежедневных проводок(Ц231)</module><action>ubrr_cess_vuz_report_dtrn</action><service>SYS$USERS</service><program>oracle@bdbp05 (TNS V1-V3)</program><plan_hash>3187855547</plan_hash><plsql_entry_object_id>4467976</plsql_entry_object_id><plsql_entry_subprogram_id>4</plsql_entry_subprogram_id><plsql_object_id>4467976</plsql_object_id><plsql_subprogram_id>4</plsql_subprogram_id><is_cross_instance>N</is_cross_instance><stats type="monitor"><stat name="duration">38</stat><stat name="elapsed_time">37984597</stat><stat name="cpu_time">1965715</stat><stat name="user_io_wait_time">33847669</stat><stat name="concurrency_wait_time">34620</stat><stat name="other_wait_time">2136593</stat><stat name="user_fetch_count">1</stat><stat name="buffer_gets">125609</stat><stat name="read_reqs">10183</stat><stat name="read_bytes">166838272</stat></stats></sql></report_repository_summary>

select * from dict where table_name like 'DBA_HIST_REP%';


--sid, serial - 13220:48478

select 
    ash.sql_id, 
    -- plan count
    (select count(distinct plan_hash_value) from dba_hist_sql_plan st where st.sql_id = ash.sql_id) awr,
    (select count(distinct plan_hash_value) from v$sql_plan st where st.sql_id = ash.sql_id) mem,
    (select count(distinct sql_plan_hash_value) from v$sql_plan_monitor st where st.sql_id = ash.sql_id) mon,
    --
    count(1) rowcount, count(1)*10 total_time, round(ratio_to_report(count(1))over(partition by nvl2(ash.sql_id,1,0)) * 100, 2) pct, 
    count(distinct sql_exec_id || to_char(sql_exec_start, 'yyyymmddhh24:mi:ss')) unq_run, 
    round(count(1)/greatest(count(distinct sql_exec_id || to_char(sql_exec_start, 'yyyymmddhh24:mi:ss')), 1), 2)*10  avg_sec,
    coalesce(
        (select to_char(substr(sql_text,1, 100)) from dba_hist_sqltext sq join v$database using(dbid) where sql_id = ash.sql_id),
        (select to_char(substr(sql_text,1, 100)) from v$sqlarea sa where sa.sql_id = ash.sql_id and rownum = 1)
    )sql_text
from dba_hist_active_sess_history ash
--    join dba_hist_snapshot s using(snap_id)
where (session_id, session_serial#) in ((13220,48478))
--    and begin_interval_time >= sysdate - 14
    and ash.sql_id is not null
group by grouping sets((sql_id),null)
order by rowcount desc nulls last;




SQL_ID               AWR        MEM        MON   ROWCOUNT TOTAL_TIME        PCT    UNQ_RUN    AVG_SEC SQL_TEXT                                                                                            
------------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------------------------------------------------------------------------------------------------
                       0          0          0         50        500        100          4        125                                                                                                     
d9vx45z6jq89b          1          0          0         28        280         56          2        140 SELECT /*+ leading(u ti t d) index(ti icontractitem_no) index(d idocuments_Opdate) */ SUM(T.VALUE) F
ay8u772x633hv          0          0          0         21        210         42          1        210 declare pragma autonomous_transaction; begin :l_ret := ubrr_cess_vuz_report.re 
5jd26bjcbf8yu          1          1          0          1         10          2          1         10 SELECT/*+ use_nl(u ti t d) index(ti ICONTRACTITEM_NO) */ SUM (VALUE) FROM UBRR_CONTRACT_CESS U, TCON





-- I_UBRR_ENTRY_BR_DOC_CR
-- I_UBRR_ENTRY_BR_DOC_DEB
SELECT --run2
--+gather_plan_statistics
    SUM(t.value)
FROM
         ubrr_contract_cess u
    JOIN tcontractitem ti ON ( ti.branch = u.branch
                               AND ti.no = u.contractno )
    JOIN a4m.tentry        t ON ( t.branch = ti.branch
                       AND t.creditaccount = ti.key )
    JOIN tdocument     d ON ( d.branch = t.branch
                          AND d.docno = t.docno )
WHERE
        1 = 1
    AND u.branch = 1--:b6
    AND u.cessnumber = 143--:b5
    AND u.enddate = TO_DATE('01.01.4000', 'dd.mm.yyyy')
    AND d.opdate = to_date('11/09/2023 00:00:00','mm/dd/yyyy hh24:mi:ss')--:b4
    AND d.docno >= 5779298815--:b3
    AND t.debitaccount LIKE 61209/*:b2*/ || '%'
    AND t.creditaccount LIKE 45511/*:b1*/ || '%';
    
    select * from table(dbms_xplan.display_cursor('drcjfhfkjnftj',0,'allstats last'));
    select * from v$sql where sql_text like '%run1%';
    
    
SQL_ID  drcjfhfkjnftj, child number 0
-------------------------------------
SELECT --+gather_plan_statistics run1     SUM(t.value) FROM          
ubrr_contract_cess u     JOIN tcontractitem ti ON ( ti.branch = 
u.branch                                AND ti.no = u.contractno )     
JOIN tentry        t ON ( t.branch = ti.branch                        
AND t.creditaccount = ti.key )     JOIN tdocument     d ON ( d.branch = 
t.branch                           AND d.docno = t.docno ) WHERE        
 1 = 1     AND u.branch = 1--:b6     AND u.cessnumber = 143--:b5     
AND u.enddate = TO_DATE('01.01.4000', 'dd.mm.yyyy')     AND d.opdate = 
to_date('11/09/2023 00:00:00','mm/dd/yyyy hh24:mi:ss')--:b4     AND 
d.docno >= 5779298815--:b3     AND t.debitaccount LIKE 61209/*:b2*/ || 
'%'     AND t.creditaccount LIKE 45511/*:b1*/ || '%'
 
Plan hash value: 3750612831
 
-------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                        | Name                    | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  |
-------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                 |                         |      1 |        |      1 |00:00:16.82 |   17100 |  15033 |
|   1 |  SORT AGGREGATE                  |                         |      1 |      1 |      1 |00:00:16.82 |   17100 |  15033 |
|   2 |   NESTED LOOPS                   |                         |      1 |        |      0 |00:00:16.82 |   17100 |  15033 |
|   3 |    NESTED LOOPS                  |                         |      1 |      1 |      0 |00:00:16.82 |   17100 |  15033 |
|   4 |     NESTED LOOPS                 |                         |      1 |      1 |      0 |00:00:16.82 |   17100 |  15033 |
|   5 |      NESTED LOOPS                |                         |      1 |      1 |      0 |00:00:16.82 |   17100 |  15033 |
|*  6 |       TABLE ACCESS BY INDEX ROWID| TENTRY                  |      1 |      1 |      0 |00:00:16.82 |   17100 |  15033 |
|*  7 |        INDEX RANGE SCAN          | I_UBRR_ENTRY_BR_DOC_DEB |      1 |      1 |      6 |00:00:04.67 |   17098 |  15031 |
|   8 |       TABLE ACCESS BY INDEX ROWID| TCONTRACTITEM           |      0 |      1 |      0 |00:00:00.01 |       0 |      0 |
|*  9 |        INDEX UNIQUE SCAN         | ICONTRACTITEM_KEY       |      0 |      1 |      0 |00:00:00.01 |       0 |      0 |
|* 10 |      TABLE ACCESS BY INDEX ROWID | UBRR_CONTRACT_CESS      |      0 |      1 |      0 |00:00:00.01 |       0 |      0 |
|* 11 |       INDEX UNIQUE SCAN          | UBRR_CONTRACT_CESS_PK   |      0 |      1 |      0 |00:00:00.01 |       0 |      0 |
|* 12 |     INDEX UNIQUE SCAN            | IDOCUMENTS_DOCNO        |      0 |      1 |      0 |00:00:00.01 |       0 |      0 |
|* 13 |    TABLE ACCESS BY INDEX ROWID   | TDOCUMENT               |      0 |      1 |      0 |00:00:00.01 |       0 |      0 |
-------------------------------------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   6 - filter("T"."CREDITACCOUNT" LIKE '45511%')
   7 - access("T"."BRANCH"=1 AND "T"."DOCNO">=5779298815 AND "T"."DEBITACCOUNT" LIKE '61209%')
       filter("T"."DEBITACCOUNT" LIKE '61209%')
   9 - access("TI"."BRANCH"=1 AND "T"."CREDITACCOUNT"="TI"."KEY")
       filter("TI"."KEY" LIKE '45511%')
  10 - filter(("U"."ENDDATE"=TO_DATE(' 4000-01-01 00:00:00', 'syyyy-mm-dd hh24:mi:ss') AND "U"."BRANCH"=1))
  11 - access("TI"."NO"="U"."CONTRACTNO" AND "U"."CESSNUMBER"=143)
  12 - access("D"."BRANCH"=1 AND "D"."DOCNO"="T"."DOCNO")
       filter("D"."DOCNO">=5779298815)
  13 - filter("D"."OPDATE"=TO_DATE(' 2023-11-09 00:00:00', 'syyyy-mm-dd hh24:mi:ss'))
 
    
    
    select count(1) From a4m.tentry t where docno >= 5779298815 and t.debitaccount LIKE 61209/*:b2*/ || '%' and branch = 1
    AND t.creditaccount LIKE 45511/*:b1*/ || '%' 
    ;
    
    select * from a4m.ubrr_contract_cess where cessnumber = 143;
    select * from dba_tab_col_statistics where table_name = 'TENTRY';
    select branch, cessnumber, count(1) from a4m.ubrr_contract_cess  group by branch, cessnumber order by 3 desc;
    
    
    
    
    
select * from dba_hist_sqltext where sql_id = 'ay8u772x633hv';
select * From dba_hist_reports where key1 = 'ay8u772x633hv';
select * from dba_hist_reports_details where report_id = 1110741;
select * From dba_hist_active_sess_history where top_level_sql_id = 'ay8u772x633hv' and (session_id, session_serial#) in ((13220,48478));

"
    declare
      pragma autonomous_transaction; 
    begin
      :l_ret := ubrr_cess_vuz_report.reestr_daily_2021(:p_errmsg,:p_date,:p_cess,:p_no);
      
      commit;
    exception 
      when others then 
        :err := dbms_utility.format_error_backtrace || dbms_utility.format_error_stack; 
        rollback;
    end;"
   