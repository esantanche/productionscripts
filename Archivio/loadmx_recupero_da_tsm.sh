#!/bin/sh 

# Questo script carica un db su di un altro ripristinando pero' la
# tabella sysusers del db destinazione

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il nome del file da recuperare"
   echo "dal TSM e originariamente presente nella directory /sybased1/dump"
   exit 0
fi

cd /sybased1/dump

dsmc <<EOF
restore $1
quit
EOF

echo $?
