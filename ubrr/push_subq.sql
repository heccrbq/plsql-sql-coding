whenever sqlerror exit rollback
alter session set optimizer_adaptive_plans=false;

drop table dropme1 purge;
create table dropme1 pctfree 0 as select object_id id, object_name name, created dt from user_objects;
create index idx_dropme1 on dropme1(dt);

drop table dropme2 purge;
create table dropme2 pctfree 0 as select * from dropme1 sample(80) seed(2);	
create index idx_dropme2 on dropme2(id);

drop table dropme3 purge;
create table dropme3 pctfree 0 as select * from dropme1 sample(80) seed(3);	
create index idx_dropme3 on dropme3(id);

exec dbms_stats.gather_table_stats(user, 'DROPME1');
exec dbms_stats.gather_table_stats(user, 'DROPME2');
exec dbms_stats.gather_table_stats(user, 'DROPME3');

select * from user_tables where table_name in ('DROPME1','DROPME2','DROPME3');   -- there're 446 952 rows in DROPME1

select count(1) from dropme1 where dt > date'2023-01-01'; -- 9 284 rows

--explain plan for
select /*+gather_plan_statistics*/ d1.* from dropme1 d1 where dt > date'2023-01-01'
and (
    exists (select /*+push_subq*/ 1 from dropme2 d2 where d2.id = d1.id)
    or
    exists (select 1 from dropme3 d3 where d3.id = d1.id)
);

select * from table(dbms_xplan.display);
select * from table(dbms_xplan.display_cursor(format=>'allstats last'));

