/**
 * =============================================================================================
 * Скрипт сравнивает 2 таблицы, а именно поля на несоответствие.
 * =============================================================================================
 * @param   comparable_table_1   	Название первой таблицы
 * @param   comparable_table_2		Название второй таблицы
 * @param   compare_columns       Формат для сравнения - ВСЕ ПОЛЯ | КАКИЕ-ТО ОПРЕДЕЛННЫЕ | ВСЕ, КРОМЕ
 * @param   compare_ddl_columns   Флаг, указывающий производить ли сверку DDL полей
 * @param   compare_cmnt_columns  Флаг, указывающий сверять ли комментарии по полям
 * @param   compare_stats_columns Флаг, указывающий сверять ли статистику по полям
 * =============================================================================================
 * Описание полей:
 *	- session_state : 
 *  - sql_opname : 
 *  - sql_plan_line_id : 
 *  - sql_plan_operation : 
 *  - sql_plan_options :  
 *	- object_name : 
 *	- current_obj : 
 *	- event : 
 *  - wait_count : 
 *  - io_req : 
 *  - cpu_time_sec : 
 *  - db_time_sec : 
 *  - percent_per_line : 
 *	- percent_per_line_state : 
 *	- percent_per_line_state_event : 
 * =============================================================================================
 */
with settings as 
(
    select
        'HCF_TSETTINGS' AS comparable_table_1,
        'TENTRY' AS comparable_table_2,
        'ALL' AS compare_columns,    -- case insensitive [ALL | INCLUDE <column_name_1>, <column_name_2>, ... <column_name_n> | EXCLUDE <column_name_1>, <column_name_2>, ... <column_name_n>]
        'Y' AS compare_ddl_columns,
--        'Y' AS compare_cmnt_columns,
--        'N' AS compare_stats_columns,
        -- 
        chr(10) || chr(13) crlf
    from dual
),
verification as
(
    select distinct
        compare_option,
        column_name
    from
        (select /*+dynamic_sampling(xt 3)*/         
            compare_option,
            upper(trim(value(xt).getstringval())) column_name
        from 
            (select
                upper(regexp_replace(s.compare_columns, '^(ALL$|INCLUDE|EXCLUDE) *(.+)','\1',1,1,'i')) compare_option,
                upper(rtrim(trim(regexp_replace(s.compare_columns, '^(ALL$|INCLUDE|EXCLUDE) *(.+)*','\2',1,1,'i')), ',')) || ',' columns_list
            from settings s) sbq, 
        xmltable('ora:tokenize(., ",")' passing sbq.columns_list)xt)
    where compare_option = 'ALL' and column_name is null
        or compare_option in ('INCLUDE', 'EXCLUDE') and column_name is not null
),
comp_ddl_col as
(
    select
        s.comparable_table_1,
        utc1.column_name column_name_on_table_1,
        s.comparable_table_2,
        utc2.column_name column_name_on_table_2,
        case 
            when utc1.table_name is null or utc2.table_name is null then
                'В таблице ' || nvl2(utc1.table_name, s.comparable_table_2, s.comparable_table_1) || ' нет поля ' || nvl(utc1.column_name, utc2.column_name)
            else 
                decode(utc1.nullable,              utc2.nullable,              null,  'nullable('              || utc1.nullable              || ' vs ' || utc2.nullable              || ')' || crlf) ||
                decode(utc1.char_used,             utc2.char_used,             null,  'char_used('             || utc1.char_used             || ' vs ' || utc2.char_used             || ')' || crlf) ||
                decode(utc1.collation,             utc2.collation,             null,  'collation('             || utc1.collation             || ' vs ' || utc2.collation             || ')' || crlf) ||
                decode(utc1.column_id,             utc2.column_id,             null,  'column_id('             || utc1.column_id             || ' vs ' || utc2.column_id             || ')' || crlf) ||
                decode(utc1.data_type,             utc2.data_type,             null,  'data_type('             || utc1.data_type             || ' vs ' || utc2.data_type             || ')' || crlf) ||
                decode(utc1.data_scale,            utc2.data_scale,            null,  'data_scale('            || utc1.data_scale            || ' vs ' || utc2.data_scale            || ')' || crlf) ||
                decode(utc1.char_length,           utc2.char_length,           null,  'char_length('           || utc1.char_length           || ' vs ' || utc2.char_length           || ')' || crlf) ||
                decode(utc1.data_length,           utc2.data_length,           null,  'data_length('           || utc1.data_length           || ' vs ' || utc2.data_length           || ')' || crlf) ||
                decode(utc3.data_default,          utc4.data_default,          null,  'data_default('          || utc3.data_default          || ' vs ' || utc4.data_default          || ')' || crlf) ||
                decode(utc1.data_type_mod,         utc2.data_type_mod,         null,  'data_type_mod('         || utc1.data_type_mod         || ' vs ' || utc2.data_type_mod         || ')' || crlf) ||
                decode(utc1.data_precision,        utc2.data_precision,        null,  'data_precision('        || utc1.data_precision        || ' vs ' || utc2.data_precision        || ')' || crlf) ||
                decode(utc1.default_length,        utc2.default_length,        null,  'default_length('        || utc1.default_length        || ' vs ' || utc2.default_length        || ')' || crlf) ||
                decode(utc1.default_on_null,       utc2.default_on_null,       null,  'default_on_null('       || utc1.default_on_null       || ' vs ' || utc2.default_on_null       || ')' || crlf) ||
                decode(utc1.identity_column,       utc2.identity_column,       null,  'identity_column('       || utc1.identity_column       || ' vs ' || utc2.identity_column       || ')' || crlf) ||
                decode(utc1.data_type_owner,       utc2.data_type_owner,       null,  'data_type_owner('       || utc1.data_type_owner       || ' vs ' || utc2.data_type_owner       || ')' || crlf) ||
                decode(utc1.character_set_name,    utc2.character_set_name,    null,  'character_set_name('    || utc1.character_set_name    || ' vs ' || utc2.character_set_name    || ')' || crlf) ||
                decode(utc1.char_col_decl_length,  utc2.char_col_decl_length,  null,  'char_col_decl_length('  || utc1.char_col_decl_length  || ' vs ' || utc2.char_col_decl_length  || ')')
        end reason
    -- user_tab_columns не содержит UNUSED полей, но они нам не особо то и нужны
    from settings s
        cross join user_tab_columns utc1
        full outer join user_tab_columns utc2 on utc1.column_name = utc2.column_name and utc2.table_name = s.comparable_table_2
        left join verification v on v.column_name in (utc1.column_name, utc2.column_name) or v.column_name is null
        outer apply
            (select
                dbms_xmlgen.convert(
                    xmlquery('for $i in //*
                        return $i/text()' passing dbms_xmlgen.getxmltype(
                        'select data_default from user_tab_columns where table_name = ''' || utc1.table_name || ''' and column_id = ''' || utc1.column_id || '''' ) returning content).getstringval(),1) data_default
            from dual) utc3
        outer apply
            (select
                dbms_xmlgen.convert(
                    xmlquery('for $i in //*
                        return $i/text()' passing dbms_xmlgen.getxmltype(
                        'select data_default from user_tab_columns where table_name = ''' || utc2.table_name || ''' and column_id = ''' || utc2.column_id || '''' ) returning content).getstringval(),1) data_default
            from dual) utc4
    where utc1.table_name = s.comparable_table_1
        and s.compare_ddl_columns = 'Y'
        and (v.compare_option = 'ALL'
         or (v.compare_option = 'INCLUDE' and utc1.column_name is not null)
         or (v.compare_option = 'EXCLUDE' and utc2.column_name is null))
)

select * from comp_ddl_col;
