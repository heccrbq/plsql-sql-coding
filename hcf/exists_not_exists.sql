--alter system flush BUFFER_CACHE;

select sql_id, plan_hash_value, child_number, sql_text from v$sql where sql_fulltext like '%asdasdasd5%' and sql_fulltext not like '%v$sql%';
select * from table(dbms_xplan.display_cursor(sql_id => 'atrkfqtnh56xx'/*:sql_id*/, cursor_child_no => 0/*:sql_child_number*/, format => 'ALLSTATS LAST'));

select /*asdasdasd1*/ /*+gather_plan_statistics*/ * from hcf_tsettings a where not exists (select value_date from HCF_TSETTINGSVALUE b where a.id = b.id);
select /*asdasdasd2*/ /*+gather_plan_statistics*/ * from hcf_tsettings a where not exists (select value_str from HCF_TSETTINGSVALUE b where a.id = b.id);
select /*asdasdasd3*/ /*+gather_plan_statistics*/ * from hcf_tsettings a where not exists (select null from HCF_TSETTINGSVALUE b where a.id = b.id);
select /*asdasdasd4*/ /*+gather_plan_statistics*/ * from hcf_tsettings a where not exists (select 1 from HCF_TSETTINGSVALUE b where a.id = b.id);

-- Все варианты работали под разным sql id, но с одним и тем же планом. При этом они не отличаются, и значением BYTES, ни количество cr, cu. Разница только в elapsed time.

Plan hash value: 263923710
--------------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                    | Name                      | Starts | E-Rows | A-Rows |   A-Time   | Buffers | Reads  |  OMem |  1Mem | Used-Mem |
--------------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |                           |      1 |        |      3 |00:00:00.23 |      72 |     42 |       |       |          |
|   1 |  MERGE JOIN ANTI             |                           |      1 |      8 |      3 |00:00:00.23 |      72 |     42 |       |       |          |
|   2 |   TABLE ACCESS BY INDEX ROWID| HCF_TSETTINGS             |      1 |    214 |    217 |00:00:00.01 |      71 |     41 |       |       |          |
|   3 |    INDEX FULL SCAN           | PK_HCF_TSETTINGS_ID       |      1 |    214 |    217 |00:00:00.01 |       1 |      1 |       |       |          |
|*  4 |   SORT UNIQUE                |                           |    217 |    311 |    214 |00:00:00.01 |       1 |      1 | 11264 | 11264 |10240  (0)|
|   5 |    INDEX FULL SCAN           | IDX_HCF_TSETTINGSVALUE_ID |      1 |    311 |    311 |00:00:00.01 |       1 |      1 |       |       |          |
--------------------------------------------------------------------------------------------------------------------------------------------------------

-- Детально это видно тут
select * from v$sql_plan_statistics_all where sql_id = 'cha7gf2yp81fr';

-- Смотрим что делает oracle при выполнении exists или not exists: Он просто убирает то, что написано в select'e даже не выполняя и заменяет на 0.
explain plan for 
  select /*+ NO_QUERY_TRANSFORMATION */ * from dual d1 
    where exists (select 1/0 from dual d2 where d2.dummy = d1.dummy);
    
select * from table(dbms_xplan.display);

Plan hash value: 341190521
---------------------------------------------------------------------------
| Id  | Operation          | Name | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |     1 |     2 |     4   (0)| 00:00:01 |
|*  1 |  FILTER            |      |       |       |            |          |
|   2 |   TABLE ACCESS FULL| DUAL |     1 |     2 |     2   (0)| 00:00:01 |
|*  3 |   TABLE ACCESS FULL| DUAL |     1 |     2 |     2   (0)| 00:00:01 |
---------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   1 - filter( EXISTS (SELECT 0 FROM "SYS"."DUAL" "D2" WHERE 
              "D2"."DUMMY"=:B1))

-- Пробуем на реальных таблицах и что происходит там:
explain plan for
SELECT /*+ NO_QUERY_TRANSFORMATION */
 *
  FROM hcf_ttran_ibs ta
   where NOT EXISTS (SELECT 1/0
          FROM ttlg tlg
          JOIN textract e
            ON e.branch = tlg.branch
           AND e.trancode = tlg.code
         WHERE tlg.branch = 1
           AND tlg.id = ta.tranid);

select * from table(dbms_xplan.display);

Plan hash value: 617511182
----------------------------------------------------------------------------------------------------------------
| Id  | Operation                              | Name                  | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                       |                       |     1 |  5370 |    10   (0)| 00:00:01 |
|*  1 |  FILTER                                |                       |       |       |            |          |
|   2 |   TABLE ACCESS FULL                    | HCF_TTRAN_IBS         |     1 |  5370 |     2   (0)| 00:00:01 |
|   3 |   VIEW                                 |                       |     1 |    13 |     8   (0)| 00:00:01 |
|   4 |    NESTED LOOPS SEMI                   |                       |     1 |    27 |     8   (0)| 00:00:01 |
|   5 |     TABLE ACCESS BY INDEX ROWID BATCHED| TTLG                  |     1 |    17 |     5   (0)| 00:00:01 |
|*  6 |      INDEX RANGE SCAN                  | ITLG                  |     1 |       |     4   (0)| 00:00:01 |
|*  7 |     INDEX RANGE SCAN                   | IEXTRACT_ORIGTRANCODE |   602M|  5741M|     3   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   1 - filter( NOT EXISTS (SELECT 0 FROM  (SELECT "TLG"."ID" "ID_0" FROM "TEXTRACT" "E","TTLG" "TLG" 
              WHERE "TLG"."ID"=:B1 AND "TLG"."BRANCH"=1 AND "E"."TRANCODE"="TLG"."CODE" AND "E"."BRANCH"=1) 
              "from$_subquery$_004"))
   6 - access("TLG"."BRANCH"=1 AND "TLG"."ID"=:B1)
   7 - access("E"."BRANCH"=1 AND "E"."TRANCODE"="TLG"."CODE")

-- Выше видно, что oracle не выполнил деление на 0, а подставил вместо этого 0

-- теперь формируем план еще раз но без хинта transformation. В полученный план добавляем search column и projection
explain plan for
SELECT
 *
  FROM hcf_ttran_ibs ta
   where NOT EXISTS (SELECT 1/0
          FROM ttlg tlg
          JOIN textract e
            ON e.branch = tlg.branch
           AND e.trancode = tlg.code
         WHERE tlg.branch = 1
           AND tlg.id = ta.tranid);

select * from table(dbms_xplan.display);
select * from plan_table where plan_id = (select max(plan_id) from plan_table) order by id;

Plan hash value: 4060409630
-------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                              | Name                  | Rows  | Bytes | Cost (%CPU)| Time     | Cols | Projection              |
-------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                       |                       |     1 |  5372 |    10   (0)| 00:00:01 |      | (#keys=0) ...           |
|   1 |  NESTED LOOPS ANTI                     |                       |     1 |  5372 |    10   (0)| 00:00:01 |      | ...                     |
|   2 |   TABLE ACCESS FULL                    | HCF_TTRAN_IBS         |     1 |  5370 |     2   (0)| 00:00:01 |      |                         |
|   3 |   VIEW PUSHED PREDICATE                | VW_SQ_1               |     1 |     2 |     8   (0)| 00:00:01 |      |                         |
|   4 |    NESTED LOOPS SEMI                   |                       |     1 |    27 |     8   (0)| 00:00:01 |      | (#keys=0)               |
|   5 |     TABLE ACCESS BY INDEX ROWID BATCHED| TTLG                  |     1 |    17 |     5   (0)| 00:00:01 |      | "TLG"."CODE"[NUMBER,22] |
|*  6 |      INDEX RANGE SCAN                  | ITLG                  |     1 |       |     4   (0)| 00:00:01 |    2 | "TLG".ROWID[ROWID,10]   |
|*  7 |     INDEX RANGE SCAN                   | IEXTRACT_ORIGTRANCODE |   602M|  5741M|     3   (0)| 00:00:01 |    2 |                         |
-------------------------------------------------------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   6 - access("TLG"."BRANCH"=1 AND "TLG"."ID"="TA"."TRANID")
   7 - access("E"."BRANCH"=1 AND "E"."TRANCODE"="TLG"."CODE")

