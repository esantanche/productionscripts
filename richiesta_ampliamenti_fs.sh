#!/bin/sh -x
#

. /home/sybase/.profile

DATA=$(/usr/bin/date +%Y%m%d-%H:%M)

#if [ $USER != sybase ] ; then
#   echo Eseguire come sybase
#   exit 0
#fi

. /sis/SIS-AUX-Envsetting.Sybase.sh
# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# DA migliorare: e' bene estrarre i dati anche della sola occupazione
# Il parametro su linea comando e' il nome del db
#NOMEDB=$1
#$UTILITY_DIR/out/lista_dei_db 

# /tmp/richiesta_ampliamenti_fs
rm -f /tmp/richiesta_ampliamenti_fs

# file richiesta richiesta_ampliamenti_fs_dimensioni_desiderate
# IL file contiene commenti inizianti per #
for file_sys in `cat $UTILITY_DIR/richiesta_ampliamenti_fs_dimensioni_desiderate | awk '!/^#/ { print $1; }'`
do
   #echo $file_sys
   #df -gM $file_sys
   DIMENSIONE_ATTUALE_FS=`df -gM $file_sys | grep $file_sys | awk '{ print $3; }'`
   #echo $DIMESIONE_ATTUALE_FS
   DIMENSIONE_VOLUTA_FS=`cat $UTILITY_DIR/richiesta_ampliamenti_fs_dimensioni_desiderate | grep $file_sys | awk '!/^#/ { print $2; }'`
   #echo $DIMENSIONE_VOLUTA_FS
   #echo $file_sys $DIMENSIONE_ATTUALE_FS $DIMENSIONE_VOLUTA_FS
   if [ $DIMENSIONE_ATTUALE_FS -lt $DIMENSIONE_VOLUTA_FS ] ; then
      echo "Il fs "$file_sys" deve essere grande complessivamente "$DIMENSIONE_VOLUTA_FS" GB" >> /tmp/richiesta_ampliamenti_fs
   fi
done

if [ ! -s /tmp/richiesta_ampliamenti_fs ] ; then
   exit
fi

echo "Subject: [RICH_AMPL] Richieste ampliamento file system Murex - "`hostname` >  /tmp/richiesta_ampliamenti_fs_$$.mail
echo "To: dba@kyneste.com"  >> /tmp/richiesta_ampliamenti_fs_$$.mail
echo "PER DBA inoltrare questa richiesta a sys@rt.kyneste.com" >> /tmp/richiesta_ampliamenti_fs_$$.mail
echo "sul tt 8081 di sys [kyneste.com #8081] che contiene" >> /tmp/richiesta_ampliamenti_fs_$$.mail
echo "tutte le richieste di ampliamento" >> /tmp/richiesta_ampliamenti_fs_$$.mail
echo "Richieste di ampliamento dei file system sulla macchina "`hostname` >> /tmp/richiesta_ampliamenti_fs_$$.mail
echo "========================================================" >> /tmp/richiesta_ampliamenti_fs_$$.mail
cat /tmp/richiesta_ampliamenti_fs >> /tmp/richiesta_ampliamenti_fs_$$.mail
echo "========================================================" >> /tmp/richiesta_ampliamenti_fs_$$.mail
echo "File completo dei dimensionamenti dei file system" >> /tmp/richiesta_ampliamenti_fs_$$.mail
cat $UTILITY_DIR/richiesta_ampliamenti_fs_dimensioni_desiderate >> /tmp/richiesta_ampliamenti_fs_$$.mail
echo "========================================================" >> /tmp/richiesta_ampliamenti_fs_$$.mail
echo "(by "$UTILITY_DIR"/richiesta_ampliamenti_fs.sh)" >> /tmp/richiesta_ampliamenti_fs_$$.mail

#cp /tmp/richiesta_ampliamenti_fs_$$.mail /inbacheca/Richiesta_ampliamenti_fs

sh $UTILITY_DIR/centro_unificato_messaggi.sh AMPLFS Richiesta_ampliam_fs 0 0 0 /tmp/richiesta_ampliamenti_fs_$$.mail 

#/usr/sbin/sendmail -f richampl@kyneste.com dba@kyneste.com < /tmp/richiesta_ampliamenti_fs_$$.mail
#/usr/sbin/sendmail -f richampl@kyneste.com sys@kyneste.com < /tmp/richiesta_ampliamenti_fs_$$.mail

rm -f /tmp/richiesta_ampliamenti_fs_$$.mail

rm -f /tmp/richiesta_ampliamenti_fs

exit

