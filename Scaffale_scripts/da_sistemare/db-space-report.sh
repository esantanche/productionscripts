#!/bin/sh -x
#
DATA=$(/usr/bin/date +%Y%m%d)

. /sis/SIS-AUX-Envsetting.Sybase.sh
# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# DA migliorare: e' bene estrarre i dati anche della sola occupazione

/usr/bin/su - sybase -c isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >$UTILITY_DIR/out/lista_dei_db <<EOF
set nocount on
go
select name from sysdatabases order by name
go
quit
EOF

tail -n +3 $UTILITY_DIR/out/lista_dei_db | awk '{ print "use ",$1; print "go"; print "sp_spaceused" ; print "go" }' - >/tmp/spacedb-script
/usr/bin/su - sybase -c isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 -i /tmp/spacedb-script >/tmp/spacedb-out
cat /tmp/spacedb-out | awk '{ if ($1 ~ /\(return/) print " "; else print $0; }' > $UTILITY_DIR/out/space-report$DATA 

cat $UTILITY_DIR/out/space-report$DATA

rm /tmp/spacedb-script
rm /tmp/spacedb-out
