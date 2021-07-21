with
-- function get_list_of_packages
function get_list_of_packages return sys.odcivarchar2list
is
begin
    -- you can specify only packages
    return sys.odcivarchar2list(    
            '&package_name'
    );
end get_list_of_packages;
-- function get_name_with_space
function get_name_with_space(p_value varchar2) return varchar2
is
    l_cnt integer := length(p_value);
    l_result varchar2(256);
begin
    while l_cnt > 0 
    loop    
        l_result := l_result || substr(p_value, coalesce(length(l_result)/2,0) + 1, 1)|| ' ';    
        l_cnt := l_cnt - 1;        
    end loop;
    
    return l_result;
end get_name_with_space;
-- function get_list_of_types
function get_list_of_types(p_type_owner varchar2, p_type_name varchar2, p_package_name varchar2) return clob-- deterministic
is
    cursor cur is
        select
            p_type_owner type_owner, 
            p_type_name type_name, 
            p_package_name package_name,
            coalesce(at.typecode, apt.typecode) typecode,
            coalesce(act.coll_type, apct.coll_type) coll_type,
            coalesce(act.upper_bound, apct.upper_bound) upper_bound,
            coalesce(act.elem_type_owner, apct.elem_type_owner) elem_type_owner,
            coalesce(act.elem_type_name, apct.elem_type_name) elem_type_name,
            apct.elem_type_package,
            apct.index_by 
        from (select p_type_owner type_owner, p_type_name type_name, p_package_name package_name from dual) t
            left join all_types at on at.owner = t.type_owner and at.type_name = t.type_name
            left join all_coll_types act on act.owner = t.type_owner and act.type_name = t.type_name
            left join all_plsql_types apt on apt.owner = t.type_owner and apt.type_name = t.type_name and apt.package_name = t.package_name
            left join all_plsql_coll_types apct on apct.owner = t.type_owner and apct.type_name = t.type_name and apct.package_name = t.package_name;
    cur_rec cur%rowtype;
    l_temp clob;
    l_result clob;
begin
    if p_type_owner is null then return null; end if;
    
    open cur;
    fetch cur into cur_rec;
    close cur;
    
    if cur_rec.typecode in ('OBJECT', 'PL/SQL RECORD') then
        select 
            'TYPE ' || lower(cur_rec.type_owner) || '.' || nvl2(cur_rec.package_name, lower(cur_rec.package_name) || '.', null) || lower(cur_rec.type_name) || 
            decode(cur_rec.typecode, 'OBJECT', ' AS OBJECT', ' IS RECORD') || chr(10) || '(' || chr(10) || 
            listagg(
                -- arguments
                '  ' || rpad(lower(ata.attr_name), ata.lpadvalue) || 
                 ' ' || case when ata.attr_type_name not in ('XMLTYPE' ,'ANYDATA') then 
                                nvl2(ata.attr_type_owner, lower(ata.attr_type_owner || '.' || nvl2(ata.attr_type_package, lower(ata.attr_type_package) || '.', null) || ata.attr_type_name), 
                                    decode(ata.attr_type_name, 'PL/SQL PLS INTEGER', 'PLS_INTEGER', 
                                                               'PL/SQL BINARY INTEGER', 'BINARY_INTEGER',
                                                               'PL/SQL BOOLEAN', 'BOOLEAN',
                                                               'PL/SQL ROWID', 'ROWID',
                                                               ata.attr_type_name))
                             else ata.attr_type_name
                             end,
                -- LISTAGG delimited
                ',' || chr(10))
            within group(order by ata.attr_no) || chr(10) || ');'
        into l_result
        from 
            (select 
                max(length(ta.attr_name))over() lpadvalue, 
                ta.attr_name,
                ta.attr_type_owner,
                ta.attr_type_name,
                null attr_type_package,
                ta.attr_no
            from all_type_attrs ta 
            where ta.owner = cur_rec.type_owner 
                and ta.type_name = cur_rec.type_name
                and cur_rec.typecode = 'OBJECT'
            union all
            select 
                max(length(apta.attr_name))over() lpadvalue,
                apta.attr_name,
                apta.attr_type_owner,
                apta.attr_type_name,
                apta.attr_type_package,
                apta.attr_no
            from all_plsql_type_attrs apta
            where apta.owner = cur_rec.type_owner 
                and apta.type_name = cur_rec.type_name
                and apta.package_name = cur_rec.package_name
                and cur_rec.typecode = 'PL/SQL RECORD') ata;
                
        for i in (
            select 
                attr_type_owner, attr_type_name, attr_type_package, max(attr_no) mx 
            from 
                (select 
                    attr_type_owner, attr_type_name, null attr_type_package, attr_no
                from all_type_attrs
                where owner = cur_rec.type_owner and type_name = cur_rec.type_name and cur_rec.typecode = 'OBJECT'
                union all
                select 
                    attr_type_owner, attr_type_name, attr_type_package, attr_no
                from all_plsql_type_attrs
                where owner = cur_rec.type_owner and type_name = cur_rec.type_name and package_name = cur_rec.package_name and cur_rec.typecode = 'PL/SQL RECORD')
            where attr_type_name not in ('XMLTYPE' ,'ANYDATA') and attr_type_owner is not null 
            group by attr_type_owner, attr_type_name, attr_type_package order by mx)
        loop
            l_result := l_result || chr(10) || chr(10) || get_list_of_types(i.attr_type_owner, i.attr_type_name, i.attr_type_package);
        end loop;
                
    elsif cur_rec.typecode = 'COLLECTION' then
        l_result := 'TYPE ' || lower(cur_rec.type_owner) || '.' || case when cur_rec.package_name is not null then lower(cur_rec.package_name) || '.' end || lower(cur_rec.type_name) || ' IS ' || 
                        case cur_rec.coll_type when 'VARYING ARRAY' then 'VARRAY' when 'PL/SQL INDEX TABLE' then 'TABLE' else cur_rec.coll_type end || 
                        case when cur_rec.upper_bound is not null then '(' || cur_rec.upper_bound || ')' end || ' OF ' || 
                        case when cur_rec.elem_type_name not in ('XMLTYPE' ,'ANYDATA') then 
                            case when cur_rec.elem_type_owner is not null 
                                then lower(cur_rec.elem_type_owner || '.' || 
                                        case when cur_rec.elem_type_package is not null then lower(cur_rec.elem_type_package) || '.' end || 
                                            cur_rec.elem_type_name) 
                                else 
                                    case cur_rec.elem_type_name when 'PL/SQL PLS INTEGER' then 'PLS_INTEGER'
                                                                when 'PL/SQL BINARY INTEGER' then 'BINARY_INTEGER'
                                                                when 'PL/SQL BOOLEAN' then 'BOOLEAN'
                                                                when 'PL/SQL ROWID' then 'ROWID'
                                                            else cur_rec.elem_type_name
                                                            end 
                                             end
                                else cur_rec.elem_type_name
                             end || case cur_rec.coll_type when 'PL/SQL INDEX TABLE' then ' INDEX BY ' || cur_rec.index_by end || ';';
        
        l_temp := get_list_of_types(cur_rec.elem_type_owner, cur_rec.elem_type_name, cur_rec.elem_type_package);
        l_result := l_result || case when l_temp is not null then chr(10) || chr(10) || l_temp end;
        
    elsif cur_rec.typecode is not null then
        raise_application_error(-20162, 'Unexpected typecode = ' || cur_rec.typecode, true);
    end if;
    
    return l_result;
end get_list_of_types;
--
obj as
(
    select
        -- header
        '/' || rpad('*' ,100, '*') || chr(10) || 
        ' ' || rpad('*' ,40 - length(object_name), '*') || ' P A C K A G E :    ' || get_name_with_space(object_name) ||
               rpad('*' ,40 - length(object_name), '*') || chr(10) || 
        ' ' || rpad('*' ,100, '*') || '/' header,
        --
        user,
        object_id,
        object_name,
        object_type
    from user_objects
    where object_type = 'PACKAGE'
        and object_name in (select column_value from table(get_list_of_packages))
),
grnt as
(
    select 
        object_id,
        -- header
        '/' || rpad('*' ,79, '*') || chr(10) || 
        ' ' || rpad('*' ,33, '*') || ' G R A N T S ' || rpad('*' ,33, '*') || chr(10) || 
        ' ' || rpad('*' ,79, '*') || '/' || chr(10) || 
        --
        listagg(x, chr(10))within group(order by rownum) grants
    from
        (select
            object_id,
            'GRANT TO ' || grantee || ':' || chr(10) ||
            listagg('  ' || privilege, chr(10))within group(order by rownum) || chr(10) x
        from all_tab_privs p,
            lateral (select object_id, object_name, object_type  from obj) o
        where p.table_name =o.object_name
            and p.type = o.object_type
        group by object_id, grantee)
    group by object_id
),
arg as 
(
    select
        object_id,
        -- header
        '/' || rpad('*' ,79, '*') || chr(10) || 
        ' ' || rpad('*' ,17, '*') || ' F U N C T I O N S   /   P R O C E D U R E S ' || rpad('*' ,17, '*') || chr(10) || 
        ' ' || rpad('*' ,79, '*') || '/' ||
        --
        dbms_xmlgen.convert(
            xmlagg(
                xmlelement(
                    rec,
                    to_clob(null) || chr(10) || object_type || ' ' || lower(object_name) || nvl2(arguments, chr(10) || '(' || chr(10), null) ||
                    arguments || nvl2(arguments, chr(10) || ')', null ) || nvl2(return_option, chr(10) || return_option,null) || ';' || 
                    nvl2(list_of_types, chr(10) || chr(10) || list_of_types, null) ||chr(10) || chr(10) ||
                    '/' || rpad('*' ,79, '*') || '/' || chr(10)
                ) order by subprogram_id
        ).extract('//text()').getclobval(),1) arguments
    from
        (select
            object_id,
            owner, 
            package_name,
            subprogram_id,
            object_type,
            object_name,
            listagg(            
                case when position > 0 then
                    -- argument name
                    '  ' || rpad(lower(argument_name), rpadvalue_arg_name) || 
                    -- in / out
                     ' ' || rpad(in_out, rpadvalue_inout) || 
                    -- argument data type 
                     ' ' || case when type_package_owner is not null or type_owner is not null then lower(type_full_name) else type_full_name end
                end
                -- LISTAGG delimiter
                ,',' || chr(10)) within group(order by owner, package_name, object_name, subprogram_id, decode(position,0,null,sequence)) arguments,
            listagg(
                -- return option
                case when position = 0 then
                   'RETURN ' ||
                    -- return data type 
                    case when type_package_owner is not null or type_owner is not null then lower(type_full_name) else type_full_name end
                end
            ) within group(order by owner, package_name, object_name, subprogram_id, decode(position,0,null,sequence)) return_option,
            listagg(
                -- list of types
                get_list_of_types(coalesce(type_package_owner, type_owner), type_name, type_package_name)
                --LISTAGG delimiter
                , chr(10)
            ) within group(order by owner, package_name, object_name, subprogram_id, decode(position,0,null,sequence)) list_of_types
        from
            (select 
                ap.object_id,
                ap.owner, 
                ap.object_name package_name,
                ap.subprogram_id,
                decode(min(aa.position)over(partition by ap.object_name, ap.procedure_name, ap.subprogram_id), 0, 'FUNCTION', 'PROCEDURE') object_type,
                ap.procedure_name object_name,
                decode(aa.position, 0 ,null, aa.sequence) sequence,
                aa.position,
                aa.argument_name,
                max(length(aa.argument_name))over(partition by ap.object_name, ap.procedure_name, ap.subprogram_id) rpadvalue_arg_name,
                aa.in_out,
                max(length(case when aa.position > 0 then aa.in_out end))over(partition by ap.object_name, ap.procedure_name, ap.subprogram_id) rpadvalue_inout,
                case when aa.type_name not in ('XMLTYPE' ,'ANYDATA') then aa.type_owner end type_owner,
                coalesce(aa.type_subname, aa.type_name, aa.pls_type, aa.data_type) type_name,
                nvl2(aa.type_subname, aa.type_owner, null) type_package_owner,
                nvl2(aa.type_subname, aa.type_name, null) type_package_name,            
                nvl2(aa.type_subname, nvl2(aa.type_owner, aa.type_owner || '.', null) || aa.type_name || '.' || type_subname,
                                   case when aa.type_owner is not null and aa.type_name not in ('XMLTYPE' ,'ANYDATA') then aa.type_owner || '.' end || coalesce(aa.type_name, aa.pls_type, aa.data_type)) type_full_name
            from all_procedures ap
                left join all_arguments aa on aa.object_id = ap.object_id and aa.subprogram_id = ap.subprogram_id and not (aa.position > 0 and aa.argument_name is null)
            where (ap.object_id, ap.object_type) in (select /*+precompute_subquery*/ object_id, object_type from obj)
                and ap.procedure_name is not null
            )
        group by object_id,
            owner, 
            package_name,
            subprogram_id,
            object_type,
            object_name)
    group by object_id
)

select 
--    o.object_id,
    o.header || chr(10) || chr(10) ||
    nvl2(g.grants, g.grants || chr(10), null) ||
    a.arguments content
from obj o
    left join grnt g on g.object_id = o.object_id
    left join arg  a on a.object_id = o.object_id

/
