select dbms_rowid.ROWID_CREATE(1,s.ROW_WAIT_OBJ#,s.ROW_WAIT_FILE#,s.ROW_WAIT_BLOCK#,s.ROW_WAIT_ROW#) rid from v$session s join v$locked_object lo on s.ROW_WAIT_OBJ#=lo.object_id;

http://apps-oracle.ru/view_blocks/

http://dbpilot.net/2018/a-blocking-session/
https://oracle-patches.com/oracle/begin/3080-%D0%B1%D0%BB%D0%BE%D0%BA%D0%B8%D1%80%D0%BE%D0%B2%D0%BA%D0%B8-oracle
https://oracle-patches.com/oracle/prof/3221-%D0%B1%D0%BB%D0%BE%D0%BA%D0%B8%D1%80%D0%BE%D0%B2%D0%BA%D0%B8-%D0%B2-%D0%B1%D0%B0%D0%B7%D0%B5-%D0%B4%D0%B0%D0%BD%D0%BD%D1%8B%D1%85-oracle



select l.*, 
o.name,
decode(L.LMODE,1,'No Lock', 
		2,'Row Share', 
		3,'Row Exclusive', 
		4,'Share', 
		5,'Share Row Exclusive', 
		6,'Exclusive',null) lmode_desc,
        decode(L.REQUEST,1,'No Lock', 
		2,'Row Share', 
		3,'Row Exclusive', 
		4,'Share', 
		5,'Share Row Exclusive', 
		6,'Exclusive',null) request_desc,
s.status, s.event, s.blocking_session from v$lock l
join v$session s on s.sid = l.sid
left join sys.obj$ o on o.obj# = decode(L.ID2,0,L.ID1,L.ID2)
where S.TYPE != 'BACKGROUND';	



select 
    lpad(' ',4*(level-1)) || sid sid, 
    s.serial#, 
    event, 
    state, 
    seconds_in_wait, 
    status
from v$session s connect by prior sid = blocking_session start with sid in (select final_blocking_session from v$session)
order siblings by s.sid;
