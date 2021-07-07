=====================================================================================================================================================================================================================
https://www.sql.ru/forum/770297-2/kak-uskorit-select-count-exists
=====================================================================================================================================================================================================================

explain plan for 
  select /*+ NO_QUERY_TRANSFORMATION */ * from dual d1 
    where exists (select to_number(d2.dummy) from dual d2 where d2.dummy = d1.dummy);
    
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
   3 - filter("D2"."DUMMY"=:B1)


Savelyev Vladimir
	Elic
		belyrabbit
			select count (1) по идее должно быстрее быть, чем select count (*)
		Не выдерживающий критики миф.


а вы можете прокомментировать следующие....

видел у разработчиков следующие:
	exists (select 1 from таблицы where услвоие and rownum=1)

сказывается каким либо образом на уменьшении потребляемых ресурсов данный подход?


Не Elic, но прокомментирую. В лучшем случае rownum=1 никак не скажется на производительности. 
Лучший случай это когда например без rownum NESTED LOOP SEMI с доступом по индексу на таблице в exists. 
С rownum будет FILTER примерно с той же производительностью. А вот если для запроса выгоден например HASH JOIN SEMI, то с rownum будет тот же FILTER и производительность конкретно просядет.

 это в принципе документированное ограничение на unnest:
 
 Unnesting of Nested Subqueries
Subquery unnesting unnests and merges the body of the subquery into the body of the statement that contains it, allowing the optimizer to consider them together when evaluating access paths and joins. 
The optimizer can unnest most subqueries, with some exceptions. Those exceptions include hierarchical subqueries and subqueries that contain a ROWNUM pseudocolumn, one of the set operators, 
a nested aggregate function, or a correlated reference to a query block that is not the immediate outer query block of the subquery.

=====================================================================================================================================================================================================================
