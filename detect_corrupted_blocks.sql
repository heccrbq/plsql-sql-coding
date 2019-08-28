-- Search corrupted blocks after RMAN
select * from dba_extents 
where (file_id,block_id) in (
     select file#, block# from v$database_block_corruption);

-- ACTION for another session like progress bar
select s.action, s.* from v$session s where osuser = sys_context('userenv','os_user');

-- PLSQL block to find corrupted blocks
set serveroutput on size unlimited
set timing on
declare
    l_nmbr integer := 0;
    detected_corrupted_block exception;
    pragma exception_init(detected_currupted_block, -1578);
begin
    for i in (select object_type, owner, object_name, count(1)over() cnt
              from dba_objects where object_type in ('TABLE', 'INDEX') and owner = 'STAGE'
              /*and object_name = 'REGULATED_REPORT_D'*/)
    loop
        l_nmbr := l_nmbr + 1;
        dbms_application_info.set_action('ELEMENT #' || l_nmbr || ' of ' || i.cnt || ': ' || 
            i.owner || '.' || i.object_name || ' (' || i.object_type || ')');
        begin
            execute immediate 'analyze ' || i.object_type || ' ' || 
                                            i.owner || '.' || 
                                            i.object_name || ' validate structure';
            exception
                when detected_corrupted_block then
                    dbms_output.put_line(i.owner || '.' || 
                                         i.object_name || 
                                         ' (' || i.object_type || ') ' ||
                                         sqlerrm);
                    
                when others then 
                    raise;
        end;
    end loop;
end;
/
