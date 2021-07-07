PARSING IN CURSOR #140092302105632 len=83 dep=6 uid=97 oct=3 lid=97 tim=9653817436025 hv=2039150142 ad='2de71dc60' sqlid='78drw7xwspxjy'
SELECT COUNT(*) CNT FROM TSTATEMENTLOGITEM WHERE BRANCH = :B2 AND PACKETCODE = :B1 
END OF STMT
PARSE #140092302105632:c=544,e=543,p=0,cr=0,cu=0,mis=1,r=0,dep=6,og=1,plh=0,tim=9653817436024
BINDS #140092302105632:

 Bind#0
  oacdty=02 mxl=22(21) mxlc=00 mal=00 scl=00 pre=00
  oacflg=03 fl2=1206001 frm=00 csi=00 siz=48 off=0
  kxsbbbfp=7f69c4bc1b78  bln=22  avl=02  flg=05
  value=1
 Bind#1
  oacdty=02 mxl=22(21) mxlc=00 mal=00 scl=00 pre=00
  oacflg=03 fl2=1206001 frm=00 csi=00 siz=0 off=24
  kxsbbbfp=7f69c4bc1b90  bln=22  avl=03  flg=01
  value=3535
EXEC #140092302105632:c=1998,e=2316,p=0,cr=0,cu=0,mis=1,r=0,dep=6,og=1,plh=2562261274,tim=9653817438427
FETCH #140092302105632:c=10199,e=10166,p=0,cr=833,cu=0,mis=0,r=1,dep=6,og=1,plh=2562261274,tim=9653817448623
STAT #140092302105632 id=1 cnt=1 pid=0 pos=1 obj=0 op='SORT AGGREGATE (cr=833 pr=0 pw=0 str=1 time=10161 us)'
STAT #140092302105632 id=2 cnt=81339 pid=1 pos=1 obj=4793952 op='INDEX RANGE SCAN PK_TSTATEMENTLOGITEM (cr=833 pr=0 pw=0 str=1 time=10509 us cost=3 size=196 card=28)'
CLOSE #140092302105632:c=0,e=1,dep=6,type=3,tim=9653817448765



mis=1 означает, что плана выражения нет в library cache и надо сделать парсинг.
В tkprof попадают только запросы с парсом. Mis=1 может быть установлен только на DML операторы и SELECT

после EXEC идут ожидания WAIT - это значит физическо чтение. Если WAIT'ов нет, как на примере ниже, значит все данные были в кэше и в блоке FETCH это видно
То есть EXEC, а по

PARSING IN CURSOR #140092302105632 len=83 dep=6 uid=97 oct=3 lid=97 tim=9653817436025 hv=2039150142 ad='2de71dc60' sqlid='78drw7xwspxjy'
SELECT COUNT(*) CNT FROM TSTATEMENTLOGITEM WHERE BRANCH = :B2 AND PACKETCODE = :B1 
END OF STMT
PARSE #140092302105632:c=544,e=543,p=0,cr=0,cu=0,mis=1,r=0,dep=6,og=1,plh=0,tim=9653817436024
BINDS #140092302105632:

 Bind#0
  oacdty=02 mxl=22(21) mxlc=00 mal=00 scl=00 pre=00
  oacflg=03 fl2=1206001 frm=00 csi=00 siz=48 off=0
  kxsbbbfp=7f69c4bc1b78  bln=22  avl=02  flg=05
  value=1
 Bind#1
  oacdty=02 mxl=22(21) mxlc=00 mal=00 scl=00 pre=00
  oacflg=03 fl2=1206001 frm=00 csi=00 siz=0 off=24
  kxsbbbfp=7f69c4bc1b90  bln=22  avl=03  flg=01
  value=3535
EXEC #140092302105632:c=1998,e=2316,p=0,cr=0,cu=0,mis=1,r=0,dep=6,og=1,plh=2562261274,tim=9653817438427
FETCH #140092302105632:c=10199,e=10166,p=0,cr=833,cu=0,mis=0,r=1,dep=6,og=1,plh=2562261274,tim=9653817448623
STAT #140092302105632 id=1 cnt=1 pid=0 pos=1 obj=0 op='SORT AGGREGATE (cr=833 pr=0 pw=0 str=1 time=10161 us)'
STAT #140092302105632 id=2 cnt=81339 pid=1 pos=1 obj=4793952 op='INDEX RANGE SCAN PK_TSTATEMENTLOGITEM (cr=833 pr=0 pw=0 str=1 time=10509 us cost=3 size=196 card=28)'
CLOSE #140092302105632:c=0,e=1,dep=6,type=3,tim=9653817448765


SELECT COUNT(*) CNT 
FROM
 TSTATEMENTLOGITEM WHERE BRANCH = :B2 AND PACKETCODE = :B1 


call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        1      0.00       0.00          0          0          0           0
Execute      1      0.00       0.00          0          0          0           0
Fetch        1      0.01       0.01          0        833          0           1
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        3      0.01       0.01          0        833          0           1
