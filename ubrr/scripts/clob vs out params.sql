
set timing on
set serveroutput on
declare
    --
    l_clob     clob;
    v_vc varchar2(32000);
    --
    l_time     number := dbms_utility.get_time;
    procedure logtime(p_message in varchar2 default null)
    is
        l_curtime number;
    begin
        l_curtime := dbms_utility.get_time;
        dbms_output.put_line(case when p_message is not null then p_message || ' : ' end || to_char(l_curtime - l_time));
        l_time:= l_curtime;
    end logtime;
    --
    procedure app(v_clob in out nocopy clob, v_vc in out nocopy varchar2, v_app varchar2) is
    begin
      v_vc := v_vc || v_app;
      exception when VALUE_ERROR then
      if v_clob is null then
        v_clob := v_vc;
      else
        dbms_lob.writeappend(v_clob, length(v_vc), v_vc);
      end if;
      v_vc := v_app;
    end;
begin    
    logtime;
    l_clob := null;
    l_clob := 'CLOB';
    logtime;
        for i in 1..1e5
        loop
            l_clob := l_clob || to_char(i);
        end loop;
        dbms_output.put_line('length:' || length(l_clob));
    logtime; 
    l_clob := null;
    l_clob := 'CLOB';
    logtime;
--        DBMS_LOB.createtemporary (l_clob, true, 2);
--        DBMS_LOB.open(l_clob,dbms_lob.lob_readwrite);
        for i in 1..1e5
        loop
            dbms_lob.writeappend(l_clob, length(i), i);
            end loop;
            dbms_output.put_line('length:' || length(l_clob));
    logtime;
    l_clob := null;
    l_clob := 'CLOB';
    logtime;
        for i in 1..1e5
        loop
            app(l_clob, v_vc, i);
        end loop;
        dbms_output.put_line('length:' || length(l_clob));
    logtime;
end;
/

