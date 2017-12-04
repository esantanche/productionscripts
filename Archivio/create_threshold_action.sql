
-----------------------------------------------------------------------------
-- DDL for Stored procedure 'sybsystemprocs.dbo.sp_thresholdaction'
-----------------------------------------------------------------------------
print 'Creating Stored procedure sp_thresholdaction'
go 

use sybsystemprocs 
go 

setuser 'dbo' 
go 

drop procedure dbo.sp_thresholdaction
go

CREATE PROCEDURE dbo.sp_thresholdaction
@dbname varchar(30),
@segmentname varchar(30),
@free_space int,
@status int
AS
  BEGIN
    declare @comando char(256), @ret int
    checkpoint
    print "X6HT THRESHOLDACTION dbname '%1!' segname '%2!' freespace '%3!' status '%4!'", @dbname, @segmentname, @free_space, @status   
    select @comando = ("sh /sybase/utility/thrproc.sh " + @dbname + " " + @segmentname + " " + convert(char(20),@free_space)
                + " " + convert(char(10),@status))
    exec @ret = xp_cmdshell @comando    
    if @ret = 1 
      print "X6HT THRESHOLDACTION xp_cmdshell failed"    
  END                                                                                                                     

go 

setuser 
go 

quit
