--The new dynamic view sys.dm_tran_locks returns information about current locks in the system. This view returns the same type of information as sp_lock but with a little bit more detail. The magic here is that it is a view, which enables the DBA to easily join it to other tables.

USE MASTER
GO

CREATE  PROCEDURE [dbo].[sp_LockDetail]
AS


BEGIN
    SELECT 
        SessionID = s.Session_id,
        resource_type,   
        DatabaseName = DB_NAME(resource_database_id),
        request_mode,
        request_type,
        login_time,
        host_name,
        program_name,
        client_interface_name,
        login_name,
        nt_domain,
        nt_user_name,
        s.status,
        last_request_start_time,
        last_request_end_time,
        s.logical_reads,
        s.reads,
        request_status,
        request_owner_type,
        objectid,
        dbid,
        a.number,
        a.encrypted ,
        a.blocking_session_id,
        a.text       
    FROM   
        sys.dm_tran_locks l --locks for sql server 2005 or newer
        JOIN sys.dm_exec_sessions s ON l.request_session_id = s.session_id -- to retrieve locking information regarding the current sessions on the server. This JOIN allows me to link up with session detail and the corresponding lock detail for that session.
        LEFT JOIN   --A LEFT JOIN is used because there will likely be current sessions on the server that may be holding some type of locks that are not currently executing. If the query execution data is there, that's great
        (
            SELECT  *
            FROM    sys.dm_exec_requests r
            CROSS APPLY sys.dm_exec_sql_text(sql_handle) --This allows me to use the sql_handle field stored in the sys.dm_exec_requests view to determine the statement being executed. The sql_handle contains a hash of the SQL statement that is currently executing
        ) a ON s.session_id = a.session_id
    WHERE  
        s.session_id > 50 -- I am filtering out any database session that is less than or equal to 50 to eliminate any system sessions
END

--I want to mark the procedure I created as a system procedure because it will allow me to run the stored procedure in any database context and retrieve information specific to that database. I have already completed the first step in marking an object as a system procedure, which is creating the object in the master database. Once I have the procedure in the master database, I need to run another system stored procedure to mark the object. Below is the call to mark the procedure as a system procedure:

USE MASTER
EXECUTE sp_ms_marksystemobject 'sp_LockDetail'
--I can execute the procedure sp_LockDetail in the context of any database on my SQL Server instance and return locking information for that database. This is much easier than creating the procedure in every user database.