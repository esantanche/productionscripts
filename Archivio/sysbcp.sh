#!/bin/sh -x
#
# Questo script salva le tabelle di sistema
# i cui nomi sono indicati nel file sysbcp-tables
# e le mette nella directory /sybase/utility/out
# Viene lanciato da crontab di sybase

. /home/sybase/.profile

DATA=$(/usr/bin/date +%Y%m%d)

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh
# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME


#DATA=$(/usr/bin/date +%Y%m%d)
#ASENAME=MX1_DEV_2
#SAPWD=capdevpwd

PATHOUT=$UTILITY_DIR/data

#cd $PATHOUT

#chmod 777 .

# ATTENZIONE LO SCRIPT VA LANCIATO CON su - sybase 

awk -v asename=$ASE_NAME -v sapwd=$SAPWD -v sauser=$SAUSER -v pathout=$PATHOUT 'BEGIN { c1="bcp master..";  
c2=" out " pathout "/" asename "-" ; 
c3=".bcp -c -P " sapwd " -S " asename " -U sa" ; }
{ print $1 ; system( c1 $1 c2 $1 c3 ) ; }
END { print "done"; }' $UTILITY_DIR/sysbcp-tables >/dev/null

#tar cvf $ASENAME-sysbcp.tar *.bcp

#cd $PATHOUT

#chmod 774 .
