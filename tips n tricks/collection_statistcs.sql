SQL> CREATE FUNCTION collection_wrapper(
  2                  p_collection IN varchar2_ntt
  3                  ) RETURN varchar2_ntt IS
  4  BEGIN
  5     RETURN p_collection;
  6  END collection_wrapper;
  7  /
  
  
  
  
  CREATE TYPE collection_wrapper_ot AS OBJECT (
  2
  3     dummy_attribute NUMBER,
  4
  5     STATIC FUNCTION ODCIGetInterfaces (
  6                     p_interfaces OUT SYS.ODCIObjectList
  7                     ) RETURN NUMBER,
  8
  9     STATIC FUNCTION ODCIStatsTableFunction (
 10                     p_function   IN  SYS.ODCIFuncInfo,
 11                     p_stats      OUT SYS.ODCITabFuncStats,
 12                     p_args       IN  SYS.ODCIArgDescList,
 13                     p_collection IN varchar2_ntt
 14                     ) RETURN NUMBER
 15
 16  );
 17  /
 
 
 
 
 
 CREATE TYPE BODY collection_wrapper_ot AS
  2
  3     STATIC FUNCTION ODCIGetInterfaces (
  4                     p_interfaces OUT SYS.ODCIObjectList
  5                     ) RETURN NUMBER IS
  6     BEGIN
  7        p_interfaces := SYS.ODCIObjectList(
  8                           SYS.ODCIObject ('SYS', 'ODCISTATS2')
  9                           );
 10        RETURN ODCIConst.success;
 11     END ODCIGetInterfaces;
 12
 13     STATIC FUNCTION ODCIStatsTableFunction (
 14                     p_function   IN  SYS.ODCIFuncInfo,
 15                     p_stats      OUT SYS.ODCITabFuncStats,
 16                     p_args       IN  SYS.ODCIArgDescList,
 17                     p_collection IN  varchar2_ntt
 18                     ) RETURN NUMBER IS
 19     BEGIN
 20        p_stats := SYS.ODCITabFuncStats(p_collection.COUNT);
 21        RETURN ODCIConst.success;
 22     END ODCIStatsTableFunction;
 23
 24  END;
 25  /
 
 
 
 
 
SQL> ASSOCIATE STATISTICS WITH FUNCTIONS collection_wrapper USING collection_wrapper_ot;

Statistics associated.





SQL> SELECT *
  2  FROM   TABLE(
  3            collection_wrapper(
  4               varchar2_ntt('A','B','C')));

Execution Plan
----------------------------------------------------------
Plan hash value: 4261576954

------------------------------------------------------------------------
| Id  | Operation                         | Name               | Rows  |
------------------------------------------------------------------------
|   0 | SELECT STATEMENT                  |                    |     3 |
|   1 |  COLLECTION ITERATOR PICKLER FETCH| COLLECTION_WRAPPER |       |
------------------------------------------------------------------------
