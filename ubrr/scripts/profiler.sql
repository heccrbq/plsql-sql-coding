 

-- https://oracle-base.com/articles/9i/dbms_profiler


select * from dba_objects where object_name in ('DBMS_PROFILER', 'DBMS_HPROF');


select * from ut3.PLSQL_PROFILER_RUNS;
select * from ut3.PLSQL_PROFILER_UNITS;
select * from ut3.PLSQL_PROFILER_DATA;

 
  
DECLARE
  l_result  BINARY_INTEGER;
BEGIN
  l_result := DBMS_PROFILER.start_profiler(run_comment => 'do_something: ' || SYSDATE);
  do_something(p_times => 100);
  l_result := DBMS_PROFILER.stop_profiler;
END;
/


CREATE OR REPLACE PROCEDURE do_something (p_times  IN  NUMBER) AS
  l_dummy  NUMBER;
BEGIN
  FOR i IN 1 .. p_times LOOP
    SELECT l_dummy + 1
    INTO   l_dummy
    FROM   dual;
  END LOOP;
END;
/


sELECT TO_CHAR (p1.total_time / 10000000, '99999999')
         || '-'
         || TO_CHAR (p1.total_occur)
            AS time_count,
            SUBSTR (p2.unit_owner, 1, 20)
         || '.'
         || DECODE (p2.unit_name,
                    '', '<anonymous>',
                    SUBSTR (p2.unit_name, 1, 20))
            AS unit,
         TO_CHAR (p1.line#) || '-' || p3.text text
    FROM ut3.plsql_profiler_data p1, 
         ut3.plsql_profiler_units p2, 
         all_source p3,
         (SELECT SUM (total_time) AS grand_total 
            FROM ut3.plsql_profiler_units) p4 
   WHERE     p2.unit_owner NOT IN ('SYS', 'SYSTEM')
         AND p1.runid = 'my application'
         AND (p1.total_time >= p4.grand_total / 100)
         AND p1.runid = p2.runid
         AND p2.unit_number = p1.unit_number
         AND p3.TYPE = 'PACKAGE BODY'
         AND p3.owner = p2.unit_owner AND p3.line = p1.line#
         AND p3.name = p2.unit_name 
ORDER BY p1.total_time DESC



