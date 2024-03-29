with function hint_validator(p_object_owner in all_objects.owner%type,
                             p_object_name  in all_objects.object_name%type,
                             p_object_type  in all_objects.object_type%type) return sys.dm_items is
    -- 
    c_single_line_hint_init_char  constant varchar2(3):= '--+';
    c_multi_line_hint_init_char   constant varchar2(3) := '/*+';
    c_multi_line_hint_final_char  constant varchar2(2) := '*/';
    c_undocumented_hint_list      constant sys.odcivarchar2list := sys.odcivarchar2list('PARALLEL');
    --
    l_sposition      integer;
    l_mposition      integer;
    l_mposition_end  integer;
    l_hint_type      varchar2(32);  -- SINGLE | MULTI
    l_raw_hint_list  dbms_sql.varchar2a;
    l_raw_index      binary_integer;
    --
    l_hint_list      sys.dm_items := sys.dm_items();
begin
    for i in (select line, text from all_source s where s.owner = p_object_owner and s.name = p_object_name and s.type = p_object_type)
    loop
        l_sposition := 1;
        l_mposition := 1;
        
        if l_hint_type is null then     
            -- find initial position
            l_sposition := instr(i.text, c_single_line_hint_init_char, 1);
            l_mposition := instr(i.text, c_multi_line_hint_init_char, 1);
            
            if l_sposition > l_mposition then
                l_hint_type := 'SINGLE';
            elsif l_mposition > l_sposition then
                l_hint_type := 'MULTI';
            end if;
        end if;
        
        if l_hint_type = 'SINGLE' then     
            -- add hints to the list
            l_hint_type             := null;
            l_raw_hint_list(i.line) := substr(i.text, l_sposition + length(c_single_line_hint_init_char));
        elsif l_hint_type = 'MULTI' then
            l_mposition_end := instr(i.text, c_multi_line_hint_final_char, l_mposition);
            
            if l_mposition_end > 0 then
                l_hint_type             := null;
                l_raw_hint_list(i.line) := substr(i.text, l_mposition + length(c_multi_line_hint_init_char), l_mposition_end - l_mposition - length(c_multi_line_hint_init_char));
            else
                l_raw_hint_list(i.line) := substr(i.text, l_mposition + length(c_multi_line_hint_init_char));
            end if;
        end if;
    end loop;
    
    l_raw_index := l_raw_hint_list.first;
    while (l_raw_index is not null)
    loop
--        dbms_output.put_line('line ' || l_raw_index || ' : ' || l_raw_hint_list(l_raw_index));
        
        for i in (
            select 
                distinct coalesce(h.name, xt.name) hint, nvl2(h.name, 'VALID', 'INVALID') status
            from xmltable('ora:tokenize(., " ")' passing regexp_replace(l_raw_hint_list(l_raw_index) || ' ', '(\([^)]*?\))') columns name varchar2(32) path '.')xt 
                left join (
                    select name from v$sql_hint 
                    union all 
                    select column_value from table(c_undocumented_hint_list)
                    ) h 
                    on h.name = upper(trim(trim(chr(10) from xt.name)))
            where xt.name is not null
            order by hint
        )
        loop
            l_hint_list.extend;
            l_hint_list(l_hint_list.count) := sys.dm_item(attribute_name      => i.hint, 
                                                          attribute_subname   => i.status,
                                                          attribute_num_value => l_raw_index, 
                                                          attribute_str_value => l_raw_hint_list(l_raw_index));
--            dbms_output.put_line('    ' || i.hint || ' (' || i.status || ')');
        end loop;
        
--        dbms_output.put_line(null);
        
        l_raw_index := l_raw_hint_list.next(l_raw_index);
    end loop;
    
    return l_hint_list;
end hint_validator;

select distinct
    ao.owner,
    ao.object_name,
    hv.attribute_name hint,
    hv.attribute_subname status,
    hv.attribute_num_value line,
    hv.attribute_str_value source
from all_objects ao,
    table(hint_validator(p_object_owner => ao.owner,
                         p_object_name  => ao.object_name,
                         p_object_type  => ao.object_type)) hv
where ao.object_type = 'PACKAGE BODY'
    and ao.owner = 'A4M'
    and ao.object_name like 'SCH_%'
    and hv.attribute_subname = 'INVALID'
order by object_name, line;
/
