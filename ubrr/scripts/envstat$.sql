select banner from gv$version;

-- main
select inst_id, name, database_role, log_mode, open_mode, flashback_on, last_open_incarnation# from gv$database;

select supplemental_log_data_all, supplemental_log_data_fk fk,  supplemental_log_data_min, supplemental_log_data_pk, supplemental_log_data_pl, supplemental_log_data_ui from gv$database;

select * from gv$instance;

select * from gv$session_wait_history where sid = 23;

select * from gv$session_wait  where sid = userenv('sid')