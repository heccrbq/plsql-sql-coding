/**
 * =============================================================================================
 * Запрос генерации датасета о продолжительности работы макросов и временных отклонениях
 * =============================================================================================
 * @param   start_date (DATE)        Дата начала работы макросов
 * @param   end_date   (DATE)        Дата окончания работы макросов
 * =============================================================================================
 * Описание полей:
 *  - branch             : бранч
 *  - code               : код макроса
 *  - name               : наименование макроса
 *  - count_line         : количество строк в макросе
 *  - last_exec_date     : время последнего выполнения макроса
 *  - last_exec_duration : продолжительность последнего выполнения макроса (в секундах)
 *  - exec_count         : общее количество выполнений макроса
 *  - exec_count_history : количество выполнений макроса, информация о которых есть в истории
 *  - exec_count_source  : количество выполнений макроса, за период между входными параметрами
 *  - last#              : время последнего выполнения макроса за период между входными параметрами (в секундах)
 *  - median#            : медианное значение времени выполнения макроса за период между входными параметрами (в секундах)
 *  - avg#               : среднее значение времени выполнения макроса за период между входными параметрами  (в секундах)
 *  - stddev#            : стандартное отклонение от avg#  (в секундах)
 *  - min#               : минимальное значение времени выполнения макроса за период между входными параметрами  (в секундах)
 *  - max#               : максимальное значение времени выполнения макроса за период между входными параметрами  (в секундах)
 */
with source as (
    select date'2021-07-01' start_date, sysdate end_date from dual
),
exec_his as (
    select 
        eh.branch, eh.code_macros,
        count(distinct eh.execid)over(partition by eh.branch, eh.code_macros) exec_count_history,
        round((max(systemdate)keep(dense_rank last order by eh.execid)over(partition by eh.branch, eh.code_macros) - 
               min(systemdate)keep(dense_rank last order by eh.execid)over(partition by eh.branch, eh.code_macros)) * 86400, 2) last_exec_duration, 
        min(case when eh.operdate between s.start_date and s.end_date then eh.execid end)over(partition by eh.branch, eh.code_macros, eh.execid) execid,
        systemdate
    from source s,
        tbpm_exechistory eh
)

select 
    -- common --
    m.branch, m.code, m.name, m.countline count_line, m.execdate last_exec_date, h.last_exec_duration, m.execcount exec_count, 
    h.exec_count_history,
    -- time stats for a <source> ago --
    count(t.execid) exec_count_source,
    max(t.exec_duration_sec)keep(dense_rank last order by t.execid) last#,
    round(median(t.exec_duration_sec), 2) median#,
    round(avg(t.exec_duration_sec), 2)    avg#,
    round(stddev(t.exec_duration_sec), 2) stddev#,
    round(min(t.exec_duration_sec), 2)    min#,
    round(max(t.exec_duration_sec), 2)    max#
from tbpm_macros m
    left join (
        select 
            e.branch, e.code_macros, e.execid, 
            round((max(e.systemdate) - min(e.systemdate)) * 86400, 2) exec_duration_sec
        from exec_his e 
        where e.execid is not null
        group by e.branch, e.code_macros, e.execid) t on t.branch = m.branch and t.code_macros = m.code
    left join (
        select 
            distinct e.branch, e.code_macros, e.exec_count_history, e.last_exec_duration
        from exec_his e
        ) h on h.branch = m.branch and h.code_macros = m.code
--where m.branch = 1 and m.code = 247
group by m.branch, m.code, m.name, m.execdate, m.countline, m.execcount, h.exec_count_history, h.last_exec_duration;
