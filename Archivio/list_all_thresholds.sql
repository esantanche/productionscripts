use sybsystemprocs
go
if exists (select name from sysobjects where name = 'sp_kydba_list_all_thresholds')
   drop procedure sp_kydba_list_all_thresholds
go
create procedure sp_kydba_list_all_thresholds
as
begin

   declare @numpgsmb 	float		/* Number of Pages per Megabyte */

   select @numpgsmb = (1048576. / v.low)
	from master.dbo.spt_values v
		 where v.number = 1
		 and v.type = "E"	

   create table #splistallthr_id_name
      (
         dbid   smallint null,
         dbname varchar(30) null
      )

   /*
   **  Initialize #splistallthr_id_name from sysdatabases
   */
   insert into #splistallthr_id_name (dbid, dbname)
                select dbid, name
                        from master.dbo.sysdatabases

   /*  select * from #splistallthr_id_name order by dbname   */

   declare @curdbid smallint		/* the one we're currently working on */
   declare @curdbname varchar(30)
   declare @dbsize int

   select @curdbname = min(dbname)                 
                from #splistallthr_id_name

   while @curdbname is not NULL
   begin
      select @curdbid = dbid from #splistallthr_id_name where dbname like @curdbname
      select @dbsize = sum(size) / @numpgsmb from master.dbo.sysusages where dbid = @curdbid
      print "id %1! name %2! size %3! MB",@curdbid, @curdbname, @dbsize

      -- use @curdbname
      -- select * from systhresholds      
      /* select * from master.dbo.sysusages where dbid = @curdbid */

      /*
      **  Now get the next, if any dbid.
      */
      select @curdbname = min(dbname) 
                from #splistallthr_id_name
			where dbname > @curdbname
   end 

   declare @pippo varchar(39)
   select @pippo = 'CAP_TEST..systhresholds'

   select * from @pippo

   return (0)
end
go
quit
