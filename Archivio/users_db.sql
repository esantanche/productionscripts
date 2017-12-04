print "ACT_CAP_SVIL"
go
select l.suid,l.name,u.uid,u.name from ACT_CAP_SVIL..sysusers u, master..syslogins l where l.suid=u.suid
go
print "CAP_REPORT"
go
select l.suid,l.name,u.uid,u.name from CAP_REPORT..sysusers u, master..syslogins l where l.suid=u.suid
go
print "CAP_SVIL"
go
select l.suid,l.name,u.uid,u.name from CAP_SVIL..sysusers u, master..syslogins l where l.suid=u.suid
go
print "CAP_TEST"
go
select l.suid,l.name,u.uid,u.name from CAP_TEST..sysusers u, master..syslogins l where l.suid=u.suid
go
print "MLC_CAP_REPORT"
go
select l.suid,l.name,u.uid,u.name from MLC_CAP_REPORT..sysusers u, master..syslogins l where l.suid=u.suid
go
print "MLC_CAP_REPORT@NEW"
go
select l.suid,l.name,u.uid,u.name from MLC_CAP_REPORT@NEW..sysusers u, master..syslogins l where l.suid=u.suid
go
print "MLC_CAP_SVIL"
go
select l.suid,l.name,u.uid,u.name from MLC_CAP_SVIL..sysusers u, master..syslogins l where l.suid=u.suid
go
print "MLC_CAP_SVIL@NEW"
go
select l.suid,l.name,u.uid,u.name from MLC_CAP_SVIL@NEW..sysusers u, master..syslogins l where l.suid=u.suid
go
print "MLC_CAP_TEST"
go
select l.suid,l.name,u.uid,u.name from MLC_CAP_TEST..sysusers u, master..syslogins l where l.suid=u.suid
go
print "MLC_CAP_TEST@NEW"
go
select l.suid,l.name,u.uid,u.name from MLC_CAP_TEST@NEW..sysusers u, master..syslogins l where l.suid=u.suid
go
print "SIF_TEST"
go
select l.suid,l.name,u.uid,u.name from SIF_TEST..sysusers u, master..syslogins l where l.suid=u.suid
go
print "dbccdb"
go
select l.suid,l.name,u.uid,u.name from dbccdb..sysusers u, master..syslogins l where l.suid=u.suid
go
print "kymx_dbadb"
go
select l.suid,l.name,u.uid,u.name from kymx_dbadb..sysusers u, master..syslogins l where l.suid=u.suid
go
print "master"
go
select l.suid,l.name,u.uid,u.name from master..sysusers u, master..syslogins l where l.suid=u.suid
go
print "model"
go
select l.suid,l.name,u.uid,u.name from model..sysusers u, master..syslogins l where l.suid=u.suid
go
print "sybsystemdb"
go
select l.suid,l.name,u.uid,u.name from sybsystemdb..sysusers u, master..syslogins l where l.suid=u.suid
go
print "sybsystemprocs"
go
select l.suid,l.name,u.uid,u.name from sybsystemprocs..sysusers u, master..syslogins l where l.suid=u.suid
go
print "tempdb"
go
select l.suid,l.name,u.uid,u.name from tempdb..sysusers u, master..syslogins l where l.suid=u.suid
go
