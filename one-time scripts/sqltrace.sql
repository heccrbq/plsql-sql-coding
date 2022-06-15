-- BEGIN dbms_session.session_trace_enable(waits=>true, binds => true); END;
-- EXECUTE DBMS_SYSTEM.SET_SQL_TRACE_IN_SESSION(1159,59930,TRUE);
-- ALTER SESSION SET SQL_TRACE=TRUE;
-- DBMS_SESSION.SET_SQL_TRACE (TRUE);


-- проверка создался ли trace файл
select 
    adr_home,
    trace_filename
from v$diag_trace_file 
where trace_filename = 
    (select instance || '_ora_' ||
        ltrim(to_char(a.spid,'fm99999')) || '.trc' filename
    from v$process a, v$session b, v$parameter c, v$thread c
    where a.addr = b.paddr
        and b.audsid = userenv('sessionid')
--		and b.sid = 1053
        and c.name = 'user_dump_dest');

/*=============================================================================================*/

-- получение текста трассы
select 
    dbms_xmlgen.convert(xmlagg(xmlelement(r, payload)).extract('//text()').getclobval(),1)
from v$diag_trace_file_contents 
where trace_filename = 'TWCMS08_ora_43155.trc';

/*=============================================================================================*/

/* трасса 10046. level 2,4,8,12:
    0 - No trace. Like switching sql_trace off.
    2 - The equivalent of regular sql_trace.
    4 - The same as 2, but with the addition of bind variable values.
    8 - The same as 2, but with the addition of wait events.
    12 - The same as 2, but with both bind variable values and wait events.*/
ALTER SESSION SET EVENTS '10046 trace name context forever, level 8';

select * from dual;

ALTER SESSION SET EVENTS '10046 trace name context off';

/*=============================================================================================*/

/* трассса 10053. level 1,2
    You have a choice of two levels with the 10053 trace event. Level 1 is more comprehensive than level 2. What is collected in the trace file includes:
    1. Parameters used by the optimizer (level 1 only)
    2. Index statistics (level 1 only)
    3. Column statistics
    4. Single Access Paths
    5. Join Costs
    6. Table Joins Considered
    7. Join Methods Considered (NL/MS/HA) */
ALTER SESSION SET EVENTS='10053 trace name context forever, level 1';

select * from dual;

ALTER SESSION SET EVENTS '10053 trace name context off';

/*=============================================================================================*/

