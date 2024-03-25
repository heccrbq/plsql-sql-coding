set echo off trimspool on linesize 200 pagesize 0 long 80000 longchunksize 200 VERIFY OFF TERMOUT OFF TIMI ON
set serverout on
spool invalid.txt
begin
  dbms_output.put_line('Start '||to_char(sysdate,'dd.mm.yyyy hh24:mi:ss'));
  begin
    sys.utl_recomp.recomp_parallel(null,'UBRR_XXI5');
--  sys.utl_recomp.recomp_parallel(null,'UBRR_DATA');
  exception when OTHERS then
    dbms_output.put_line(sqlerrm);
  end;
/*
  sys.utl_recomp.recomp_serial('UBRR_XXI5');
  sys.utl_recomp.recomp_serial('UBRR_DATA');
  dbms_output.put_line('utl_recomp '||to_char(sysdate,'dd.mm.yyyy hh24:mi:ss'));
*/
  for o in
  (
    select * from all_objects where status='INVALID' and owner='UBRR_XXI5' order by last_ddl_time desc
  ) loop
    if o.OBJECT_TYPE in ('PACKAGE') then
        dbms_output.put_line(o.OWNER||'.'||o.OBJECT_NAME||' '||o.OBJECT_TYPE);
        begin
                execute immediate('alter package '||o.OWNER||'.'||o.OBJECT_NAME||' compile reuse settings');
        exception when OTHERS then
         dbms_output.put_line(sqlerrm);
         for e in
         (
           select * from dba_errors where owner=o.OWNER and name=o.OBJECT_NAME and type=o.OBJECT_TYPE order by MESSAGE_NUMBER
         ) loop
                dbms_output.put_line(e.TEXT);
         end loop;
        end;
    end if;
    if o.OBJECT_TYPE in ('PACKAGE BODY') then
        dbms_output.put_line(o.OWNER||'.'||o.OBJECT_NAME||' '||o.OBJECT_TYPE);
        begin
                execute immediate('alter package '||o.OWNER||'.'||o.OBJECT_NAME||' compile body reuse settings');
        exception when OTHERS then
         dbms_output.put_line(sqlerrm);
         for e in
         (
           select * from dba_errors where owner=o.OWNER and name=o.OBJECT_NAME and type=o.OBJECT_TYPE order by MESSAGE_NUMBER
         ) loop
                dbms_output.put_line(e.TEXT);
         end loop;
        end;
    end if;
  end loop;
  for o in
  (
    select o.*
    from all_objects o,all_synonyms s
    where o.owner=s.owner and o.object_name=s.synonym_name and s.table_owner in ('UBRR_XXI5','UBRR_DATA')
        and o.status='INVALID' and o.owner='PUBLIC' and o.object_type = 'SYNONYM' order by last_ddl_time desc
  ) loop
        dbms_output.put_line(o.OWNER||'.'||o.OBJECT_NAME||' '||o.OBJECT_TYPE);
        begin
                execute immediate('alter public synonym '||o.OBJECT_NAME||' compile');
        exception when OTHERS then
         dbms_output.put_line(sqlerrm);
         for e in
         (
           select * from dba_errors where owner=o.OWNER and name=o.OBJECT_NAME and type=o.OBJECT_TYPE order by MESSAGE_NUMBER
         ) loop
                dbms_output.put_line(e.TEXT);
         end loop;
        end;
  end loop;
end;
/
show error
quit
