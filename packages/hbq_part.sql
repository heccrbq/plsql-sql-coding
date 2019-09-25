create or replace package hbq_part is

    /**
     * =============================================================================================
     * Пакет автоматического добавления партиций
     * =============================================================================================
     * @author  heccrbq
     */
    
    type hbq_partition is record (
        partition_name       varchar2(255),
        partition_tablespace varchar2(255),
        high_value           varchar2(255),
        high_value_date      date);
        
    type hbq_partition_list is table of hbq_partition;
    
    /**
     * =============================================================================================
     * Процедура нарезки новых партиций для таблицы A4M.TADJPACK
     * =============================================================================================
     */
    procedure cut_tadjpack;
    
    /**
     * =============================================================================================
     * Процедура подготовки метаданных для нарезки партиций
     * =============================================================================================
     * @param   p_table_owner   Пользователь/владелец таблицы
     * @param   p_table_name    Название таблицы
     * @param   p_part_date     Дата, от которой нарезатся партиции
     * @param   p_period        Период в месяцах, в течение которого надо нарезать партициию от p_part_date
     * @param   p_period_type   Тип указанного периода: Y - yearly, M - monthly, D - daily
     * @return                  Возвращает коллекцию с метаданными для нарезки партиций
     */
    function prepare_partition_data (p_table_owner   varchar2,
                                     p_table_name    varchar2,
                                     p_part_date     date,
                                     p_period        integer,
                                     p_period_type   char) return hbq_part.hbq_partition_list;
    
    /**
     * =============================================================================================
     * Процедура добавления новых партиций к таблице на основе коллекции hbq_part_list 
     * =============================================================================================
     * @param   p_table_owner       Пользователь/владелец таблицы
     * @param   p_table_name        Название таблицы
     * @param   p_partition_list    Коллекция, содержащая информацию о создаваемых партициях
     */
    procedure add_partition(p_table_owner    varchar2,
                            p_table_name     varchar2,
                            p_partition_list hbq_part.hbq_partition_list);
    
end hbq_part;
/
create or replace package body hbq_part is

    /**
     * =============================================================================================
     * Процедура нарезки новых партиций для таблицы A4M.TADJPACK
     * =============================================================================================
     */
    procedure cut_tadjpack
    is
        l_owner varchar2(255) := 'A4M';
        l_table_name varchar2(255) := 'TADJPACK';
        l_part_date date := trunc(sysdate);
        l_period integer := 6;
        l_period_type char(1) := 'M';
        l_part_list hbq_part.hbq_partition_list;
    begin
        -- Подготавливаем набор будущих партиций
        l_part_list := hbq_part.prepare_partition_data( p_table_owner  => l_owner,
                                                              p_table_name    => l_table_name,
                                                              p_part_date     => l_part_date,
                                                              p_period        => l_period,
                                                              p_period_type   => l_period_type );

        -- Нарезка партиций
        hbq_part.add_partition( p_table_owner    => l_owner,
                                      p_table_name     => l_table_name,
                                      p_partition_list => l_part_list );
    end cut_tadjpack;
    
    /**
     * =============================================================================================
     * Процедура подготовки метаданных для нарезки партиций
     * =============================================================================================
     * @param   p_table_owner   Пользователь/владелец таблицы
     * @param   p_table_name    Название таблицы
     * @param   p_part_date     Дата, от которой нарезатся партиции
     * @param   p_period        Период в месяцах, в течение которого надо нарезать партициию от p_part_date
     * @param   p_period_type   Тип указанного периода: Y - yearly, M - monthly, D - daily
     * @return                  Возвращает коллекцию с метаданными для нарезки партиций
     */
    function prepare_partition_data (p_table_owner   varchar2,
                                     p_table_name    varchar2,
                                     p_part_date     date,
                                     p_period        integer,
                                     p_period_type   char) return hbq_part.hbq_partition_list
    is
        l_part      hbq_part.hbq_partition;
        l_part_list hbq_part.hbq_partition_list := hbq_part.hbq_partition_list();
    begin
        -- Проверяем, что тип периода для нарезки среди определенного пула
        if p_period_type not in ('D', 'M', 'Y') then
            raise_application_error(-20001, 'Период должен быть одним из трех значений: D, M, Y.', true);
        end if;
        
        -- Получим инфу о последней партиции
        $if dbms_db_version.version >= 12 $then
            select
                partition_name, tablespace_name, high_value, null
            into l_part
            from all_tab_partitions
            where table_owner = p_table_owner
                and table_name = p_table_name
            order by partition_position desc fetch first 1 row only;
        $else
            select
                l_part(partition_name, tablespace_name, high_value)
            into l_part
            from
            (
                select
                    partition_name, tablespace_name, high_value
                from all_tab_partitions
                where table_owner = p_table_owner
                    and table_name = p_table_name
                order by partition_position desc
            )
            where rownum = 1;
        $end        
        
        -- Преобразуме high_value из varchar2 в дату для использования в запросе ниже
        execute immediate 'begin :1 := ' || l_part.high_value || '; end;' using out l_part.high_value_date;
        
        -- Формируем набор партиций для нарезки по шаблону PAR_yyyymmdd
        select 
            'PAR_' || decode(period, 'D', to_char(high_value_date - 1, 'yyyymmdd'),
                                     'M', to_char(high_value_date - 1, 'yyyymm'),
                                     'Y', to_char(high_value_date - 1, 'yyyy')) part_name,
            l_part.partition_tablespace,
            'TO_DATE(''' || to_char(high_value_date, 'syyyy-mm-dd hh24:mi:ss') || ''', ''SYYYY-MM-DD HH24:MI:SS'', ''NLS_CALENDAR=GREGORIAN'')' high_value,
            high_value_date
        bulk collect into l_part_list
        from
        (
            select
                period,
                decode(period, 'D', trunc(part_date) + level + 1,
                               'M', trunc(add_months(part_date, level + 1), 'month'),
                               'Y', trunc(add_months(part_date, 12*(level + 1)), 'year')) high_value_date
            from 
            (
                select             
                    p_period_type as period,
                    p_part_date as part_date
                from dual
            )
            connect by level <= p_period
        )
        where high_value_date > l_part.high_value_date;
        
        return l_part_list;
    exception 
        when no_data_found then
            raise_application_error(-20001, 'Таблица не найдена или не является партицированной.', true);
    end prepare_partition_data;
    
    /**
     * =============================================================================================
     * Процедура добавления новых партиций к таблице на основе коллекции hbq_part 
     * =============================================================================================
     * @param   p_table_owner       Пользователь/владелец таблицы
     * @param   p_table_name        Название таблицы
     * @param   p_partition_list    Коллекция, содержащая информацию о создаваемых партициях
     */
    procedure add_partition(p_table_owner    varchar2,
                            p_table_name     varchar2,
                            p_partition_list hbq_part.hbq_partition_list)
    is
        l_part_val hbq_part.hbq_partition;
        l_sql varchar2(32767) := 'alter table "#owner#"."#table_name#" add #partition_list#';
        l_part_list varchar2(300) := 'partition #partition_name# values less than (#date#) tablespace "#tablespace_name#"';
        l_full_part_list varchar2(32767);
    begin
        dbms_output.put_line(p_partition_list.count || ' partition(s) will be added.');
        
        -- Если данные для добавления партиций были сгенерированы
        if p_partition_list.count > 0 then
            $if dbms_db_version.version >= 12 $then
                for i in p_partition_list.first .. p_partition_list.last
                loop
                    l_part_val := p_partition_list(i);
                    l_full_part_list := l_full_part_list || 
                        replace(
                            replace(
                                replace(l_part_list, '#partition_name#', l_part_val.partition_name),
                                                     '#date#', l_part_val.high_value),
                                                     '#tablespace_name#', l_part_val.partition_tablespace) || ', ';
                end loop;
                
                l_sql := replace(
                             replace(
                                 replace(l_sql, '#owner#', p_table_owner),
                                                '#table_name#', p_table_name),
                                                '#partition_list#', rtrim(l_full_part_list, ', '));
            
                execute immediate l_sql;
            $else
                for i in p_partition_list.first .. p_partition_list.last
                loop
                    l_part_val := p_partition_list(i);
                    l_full_part_list := replace(
                                       replace(
                                           replace(l_part_list, '#partition_name#', l_part_val.partition_name),
                                                                '#date#', l_part_val.high_value),
                                                                '#tablespace_name#', l_part_val.partition_tablespace);
                    l_sql := replace(
                                 replace(
                                     replace(l_sql, '#owner#', p_table_owner),
                                                    '#table_name#', p_table_name),
                                                    '#partition_list#', l_full_part_list);
                    
                    execute immediate l_sql;
                end loop;
            $end
        end if;
    end add_partition;
    
end hbq_part;
/
