1. посмотреть, что DELETE всегда идет вместе с DELETE STATEMENT





BITMAP AND 
BITMAP CONVERSION FROM ROWIDS
BITMAP CONVERSION TO ROWIDS
BITMAP OR 
BUFFER SORT
COLLECTION ITERATOR CONSTRUCTOR FETCH
COLLECTION ITERATOR PICKLER FETCH
CONCATENATION 
CONNECT BY NO FILTERING WITH START-WITH
CONNECT BY NO FILTERING WITH SW (UNIQUE)
CONNECT BY PUMP 
CONNECT BY WITH FILTERING
CONNECT BY WITH FILTERING (UNIQUE)
CONNECT BY WITHOUT FILTERING
COUNT 
COUNT STOPKEY


====================================================================================================
CREATE TABLE STATEMENT
====================================================================================================
	корневая операция, которая свидетельствует о том, что результатом выполнения всех шагов плана станет создание таблицы - выполнен CREATE TABLE
	
explain plan for
    create table dropme as select * from dual;
	
-------------------------------------------------------------------------------------------
| Id  | Operation                        | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------
|   0 | CREATE TABLE STATEMENT           |        |     1 |     2 |     3   (0)| 00:00:01 |
|   1 |  LOAD AS SELECT                  | DROPME |       |       |            |          |
|   2 |   OPTIMIZER STATISTICS GATHERING |        |     1 |     2 |     2   (0)| 00:00:01 |
|   3 |    TABLE ACCESS FULL             | DUAL   |     1 |     2 |     2   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------


====================================================================================================
DELETE 
====================================================================================================
	операция, которая говорит о том, что из указанного объекта производится удаление строк. Операция комбинируется с row source: DELETE STATEMENT
	
explain plan for
    delete from dropme;
	
-----------------------------------------------------------------------------
| Id  | Operation          | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------
|   0 | DELETE STATEMENT   |        |     1 |     3 |     3   (0)| 00:00:01 |
|   1 |  DELETE            | DROPME |       |       |            |          |
|*  2 |   TABLE ACCESS FULL| DROPME |     1 |     3 |     3   (0)| 00:00:01 |
-----------------------------------------------------------------------------


====================================================================================================
DELETE STATEMENT 
====================================================================================================
	корневая операция, которая свидетельствует о том, что результатом выполнения всех шагов плана станет удаление строк - выполнен DELETE.
	Операция комбинируется с row source: DELETE 

explain plan for
    delete from dropme;
	
-----------------------------------------------------------------------------
| Id  | Operation          | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------
|   0 | DELETE STATEMENT   |        |     1 |     3 |     3   (0)| 00:00:01 |
|   1 |  DELETE            | DROPME |       |       |            |          |
|*  2 |   TABLE ACCESS FULL| DROPME |     1 |     3 |     3   (0)| 00:00:01 |
-----------------------------------------------------------------------------


====================================================================================================
DIRECT LOAD INTO 
====================================================================================================


DIRECT LOAD INTO (CURSOR DURATION MEMORY)
EXPRESSION EVALUATION 
FAST DUAL 
FILTER 
FIRST ROW 
FIXED TABLE FIXED INDEX
FIXED TABLE FULL
FOR UPDATE 
HASH GROUP BY
HASH GROUP BY PIVOT
HASH JOIN 
HASH JOIN ANTI
HASH JOIN ANTI BUFFERED
HASH JOIN ANTI NA
HASH JOIN ANTI NA BUFFERED
HASH JOIN ANTI SNA
HASH JOIN BUFFERED
HASH JOIN FULL OUTER
HASH JOIN FULL OUTER BUFFERED
HASH JOIN OUTER
HASH JOIN OUTER BUFFERED
HASH JOIN RIGHT ANTI
HASH JOIN RIGHT ANTI BUFFERED
HASH JOIN RIGHT ANTI NA
HASH JOIN RIGHT OUTER
HASH JOIN RIGHT OUTER BUFFERED
HASH JOIN RIGHT SEMI
HASH JOIN RIGHT SEMI BUFFERED
HASH JOIN SEMI
HASH JOIN SEMI BUFFERED
HASH UNIQUE
INDEX FAST FULL SCAN
INDEX FULL SCAN
INDEX FULL SCAN (MIN/MAX)
INDEX RANGE SCAN
INDEX RANGE SCAN (MIN/MAX)
INDEX RANGE SCAN DESCENDING
INDEX SAMPLE FAST FULL SCAN
INDEX SKIP SCAN
INDEX UNIQUE SCAN
INLIST ITERATOR 
INSERT STATEMENT 
INTERSECTION 
JOIN FILTER CREATE
JOIN FILTER USE
LOAD AS SELECT 
LOAD AS SELECT (CURSOR DURATION MEMORY)
LOAD AS SELECT (HYBRID TSM/HWMB)
LOAD AS SELECT (TEMP SEGMENT MERGE)
LOAD TABLE CONVENTIONAL 
MAT_VIEW ACCESS FULL
MERGE 
MERGE JOIN 
MERGE JOIN ANTI NA
MERGE JOIN ANTI SNA
MERGE JOIN CARTESIAN
MERGE JOIN OUTER
MERGE JOIN SEMI
MERGE STATEMENT 
MINUS 
MULTI-TABLE INSERT 
NESTED LOOPS 
NESTED LOOPS ANTI
NESTED LOOPS ANTI SNA
NESTED LOOPS OUTER
NESTED LOOPS SEMI
OPTIMIZER STATISTICS GATHERING 
PART JOIN FILTER CREATE
PARTITION COMBINED ITERATOR
PARTITION LIST ALL
PARTITION LIST SINGLE
PARTITION RANGE ALL
PARTITION RANGE ITERATOR
PARTITION RANGE JOIN-FILTER
PARTITION RANGE SINGLE
PARTITION REFERENCE ALL
PARTITION REFERENCE SINGLE
PX BLOCK ITERATOR
PX COORDINATOR 
PX COORDINATOR FORCED SERIAL
PX RECEIVE 
PX SELECTOR 
PX SEND 1 SLAVE
PX SEND BROADCAST
PX SEND HASH
PX SEND HASH (BLOCK ADDRESS)
PX SEND HYBRID HASH
PX SEND HYBRID HASH (SKEW)
PX SEND QC (ORDER)
PX SEND QC (RANDOM)
PX SEND RANGE
PX SEND ROUND-ROBIN
RECURSIVE WITH PUMP 
REMOTE 
SELECT STATEMENT 
SEQUENCE 
SORT AGGREGATE
SORT GROUP BY
SORT GROUP BY NOSORT
SORT GROUP BY NOSORT PIVOT
SORT GROUP BY PIVOT
SORT GROUP BY ROLLUP
SORT GROUP BY ROLLUP COLLECTOR
SORT GROUP BY ROLLUP DISTRIBUTOR
SORT GROUP BY STOPKEY
SORT JOIN
SORT JOIN (REUSE)
SORT ORDER BY
SORT ORDER BY STOPKEY
SORT UNIQUE
SORT UNIQUE NOSORT
SORT UNIQUE STOPKEY
STATISTICS COLLECTOR 
TABLE ACCESS BY GLOBAL INDEX ROWID
TABLE ACCESS BY GLOBAL INDEX ROWID BATCHED
TABLE ACCESS BY INDEX ROWID
TABLE ACCESS BY INDEX ROWID BATCHED
TABLE ACCESS BY LOCAL INDEX ROWID
TABLE ACCESS BY LOCAL INDEX ROWID BATCHED
====================================================================================================
TABLE ACCESS BY USER ROWID
====================================================================================================
	путь доступа к данным, при котором по ROWID(указатель физического местоположения строки) поднимается конкретная строка. Является самым быстрым доступом к данным таблицы.

explain plan for
    select * from dropme where rowid = 'AAfJD6AIUAAAEKGAAA';

-------------------------------------------------------------------------------------
| Id  | Operation                  | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT           |        |     1 |     3 |     1   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY USER ROWID| DROPME |     1 |     3 |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------


====================================================================================================
TABLE ACCESS CLUSTER
====================================================================================================


====================================================================================================
TABLE ACCESS FULL
====================================================================================================
	путь доступа к данным, при котором таблица читается целиком. Стоить помнить, что до Low HWM таблица читается многоблочно. с Low HWM до HWM одноблочно.
	
explain plan for
    select * from dropme;
	 
----------------------------------------------------------------------------
| Id  | Operation         | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |        |    10 |    30 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS FULL| DROPME |    10 |    30 |     3   (0)| 00:00:01 |
----------------------------------------------------------------------------


====================================================================================================
TABLE ACCESS SAMPLE
====================================================================================================
	путь доступа к данным, при котором читается только определнный процент блоков таблицы (в данном случае 10%). Стоить помнить, что есть seed, который может
	застолбить данный набор данных.

explain plan for
    select * from dropme sample (10);
    
------------------------------------------------------------------------------
| Id  | Operation           | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------
|   0 | SELECT STATEMENT    |        |     1 |     3 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS SAMPLE| DROPME |     1 |     3 |     3   (0)| 00:00:01 |
------------------------------------------------------------------------------


TEMP TABLE TRANSFORMATION 
TRANSPOSE 
UNION ALL (RECURSIVE WITH) BREADTH FIRST
UNION ALL PUSHED PREDICATE 
UNION-ALL 
UNION-ALL PARTITION
UNPIVOT 
UPDATE 
UPDATE STATEMENT 
VIEW 
VIEW PUSHED PREDICATE 
WINDOW BUFFER
WINDOW BUFFER PUSHED RANK
WINDOW CHILD PUSHED RANK
WINDOW NOSORT
WINDOW NOSORT STOPKEY
WINDOW SORT
WINDOW SORT PUSHED RANK
XMLTABLE EVALUATION 
XPATH EVALUATION 


drop table dropme;
create table dropme as select level x from dual connect by level <= 10;
