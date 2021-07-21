/********************************************

undo_retention и авторасширение датафайлов UNDO тейблспейса
	https://blog.toadworld.com/undo-rentention-time-with-autoextend-on-and-autoextend-off
	
Анализ статистики использования UNDO
	https://blog.toadworld.com/blog/2017/07/25/how-to-analyze-undo-statistics-to-proactively-avoid-undo-space-issues
	
Как оракл переисползует Просроченные и НЕпросроченные undo блоки
	https://blog.toadworld.com/how-does-oracle-reuse-expired-and-unexpired-undo-extents
	
************************************************************************************/


-- ретроспективный запрос (flashbask query). Читает данные из undo. На его работу влияет увеличение undo_retention, ну и размер undo тбс
select .. AS OF TIMESTAMP(SYSDATE - 3/24)

sho parameter undo

NAME              TYPE    VALUE    
----------------- ------- -------- 
temp_undo_enabled boolean FALSE    
undo_management   string  AUTO     
undo_retention    integer 28800    
undo_tablespace   string  UNDOTBS1

Тот, который показывается в v$database - это flashback database (не имеет отношения к undo).


select LOG_MODE, FLASHBACK_ON from v$database;

----------- -----------
ARCHIVELOG	NO

select retention from dba_tablespaces where contents='UNDO';

----------------------
NOGUARANTEE

select file_name, autoextensible from dba_data_files where tablespace_name='UNDOTBS1'


-- undo size
select sum(a.bytes) as undo_size from v$datafile a, v$tablespace b, dba_tablespaces c 
where c.contents = 'UNDO' and c.status = 'ONLINE' and b.name = c.tablespace_name and a.ts# = b.ts#;

-- использование undo
select sid, substr(username, 1, 15) "Username",
  s.osuser,s.module,
	substr(r.name, 1, 15) "Undo segment",
	substr(ds.tablespace_name, 1, 10) "Tablespace",
	used_urec "Undo recs", used_ublk "Undo blks",
	t.status "Tx Status"
from v$session s, v$transaction t, v$rollname r, dba_segments ds
where s.saddr=t.ses_addr and r.usn=t.xidusn and ds.segment_name=r.name
order by used_urec desc;


select * from dba_hist_undostat where maxquerysqlid = 'ff8wx3qsmwr3r' order by end_time desc;
select * From dba_rollback_segs where segment_name = '_SYSSMU7_2222201729$';
select * From dba_undo_extents where segment_name = '_SYSSMU7_2222201729$';;
select * From v$undostat order by begin_time desc;
select * from v$rollstat;
select * from v$transaction;


-- Статистика по EXPIRED, UNEXPIRED и ACTIVE экстентам в сегментах отката
select status,tablespace_name, sum(bytes)/1024/1024/1024 gb, count(*) 
from dba_undo_extents 
--where segment_name= '_SYSSMU13_255834700$'
group by status, tablespace_name;


-- rollback segment per session with transasction
select a.sid, a.username, a.osuser, a.program, round(b.used_ublk*8/1024) as "RBS Size, MB",
  b.used_urec as "Undo records", b.used_ublk as "Undo blocks", c.name "RBS Name", b.start_time
from v$session a, v$transaction b, v$rollname c
where b.addr = a.taddr and c.usn = b.xidusn;


/**********************************************************************************************************************
  SNAPSHOT TOO OLD
  
  In summary, follow these practices to avoid seeing error ORA-01555 in the future:

Do not run discrete queries and sensitive queries simultaneously unless the data is mutually exclusive.
If possible, schedule queries during off-peak hours to ensure consistent read blocks do not need to rollback changes.
Use large optimal values for rollback segments.
Use a large database block size to maximize rollback segment transaction table slots.
Reduce transaction slot reuse by performing less commits, especially in PL/SQL queries.
Avoid committing inside a cursor loop.
Do not fetch between commits, especially if the data queried by the cursor is being changed in the current session.
Optimize queries to read fewer data and take less time to reduce the risk of consistent get rollback failure.
Increase the size of your UNDO tablespace, and set the UNDO tablespace in GUARANTEE mode.
When exporting tables, export with CONSISTENT = no parameter.
 **********************************************************************************************************************/
 
 
 
 
select * from dba_hist_undostat where maxquerysqlid = 'ff8wx3qsmwr3r' order by end_time desc;
select * From dba_rollback_segs where segment_name = '_SYSSMU7_2222201729$';
select * From dba_undo_extents where segment_name = '_SYSSMU13_255834700$';;
select * From v$undostat order by begin_time desc;
select * from v$rollstat;
