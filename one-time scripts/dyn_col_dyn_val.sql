/**
 * Суть скрипта в том, чтобы поискать набор значений (vallist) в заранее известных полях всех таблиц бд (tbllist)
 * Результатом скрипта является список из таблицы и запроса к ней, который дал одну строку результата
 */

with vallist as (select * from table(sys.ku$_objnumset(100,200,300,400))) -- not more than 1000 elements
    ,tbllist as (select owner, table_name, column_name from all_tab_columns where owner = 'A4M' and column_name in ('IDCLIENT', 'ID_CLIENT', 'CLIENTID', 'CLIENT_ID'))
    ,qrylist as (
        select 
            owner || '.' || table_name tbl,
            'select 1 x from ' || owner || '.' || table_name || ' where ' || 
            listagg(column_name || ' in ' || 
                (select '(' || listagg(column_value, ',')within group(order by rownum) || ')' from vallist), ' or ')within group(order by column_name) ||
            ' and rownum = 1' sql
        from tbllist
        group by owner, table_name)
        
-- run all queries and show the tables, containing the values from the vallist
select tbl, sql, value(xt).getnumberval() row$ from qrylist, xmltable('/ROWSET/ROW/X/text()' passing dbms_xmlgen.getxmltype(sql)) xt
