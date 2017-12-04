#!/bin/sh

# Questo script amplia un database
# Si ipotizza che il database abbia un device il cui nome sia quello del db con il suffisso #D01 per i dati
# e #L01 per il log (qui ci occupiamo solo della parte dati)
# Se il db dovesse avere un device di suffisso D02, si usera' quest'ultimo ipotizzando che sia piu'
# recente e che sia quello da utilizzare

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then
        exit 0;
fi

if [ $1a = a -o $2a = a ] ; then
   echo "Usage: dare come parametri il nome del db da ampliare e la size di ampliamento in MB"
   exit 0
fi

NOMEDB=$1
SIZE=$2

# Verifico che il db esista
DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$NOMEDB"
go
exit
EOF`

#echo $DBESISTENTE

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $NOMEDB " non esiste."
   exit 0
fi

# Trovo il device da ampliare il cui nome e' dato dal nome del database con un suffisso #D01 o #D02 ecc.
DEVICE_DA_AMPLIARE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DEVICE_DA_AMPLIARE/ { print $2; }'
select "DEVICE_DA_AMPLIARE",max(name) from sysdevices where name like "${NOMEDB}#M%"
go
exit
EOF`

#echo $DEVICE_DA_AMPLIARE

if [ $DEVICE_DA_AMPLIARE = 'NULL' ] ; then
   echo "Il db " $NOMEDB " non ha il device con suffisso #Mnn"
   echo "ovvero di nome ${NOMEDB}#Mnn."
   echo "Lo script non puo' eseguire l'ampliamento"
   exit 0
fi

clear
echo " "
echo "Questo script ampliera' il db " $NOMEDB " per la parte dati di " $SIZE " MB "
echo "Verra' ampliato con una disk resize il device "$DEVICE_DA_AMPLIARE
echo " "
echo "Controllare bene in particolare la size dell'ampliamento poi"
echo "dare S poi invio per avviare l'operazione o N e invio per non proseguire"
read risposta
if [ $risposta != "S" ] ; then
   exit 0;
fi
echo " "
echo " "

echo "============================================================="
echo "Eseguo il resize..."
echo "  "

# Calcolo la size attuale del device perche' dovro' ottenere la size finale,
# ampliamento compreso, del device

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF > /tmp/db-ampliamento-dati-lowhigh
declare @low int, @high int
select @low = 0
select @high = 0
select @low = low, @high = high from sysdevices where name = '$DEVICE_DA_AMPLIARE'
if @@error != 0 select 'ERRORELH'
select 'LOWHIGH',@low,@high
if @@error != 0 select 'ERRORELH'
if @high = 0 select 'ERRORELH'
go
exit
EOF

ERRORE_LOW_HIGH=`grep ERRORELH /tmp/db-ampliamento-dati-lowhigh | wc -l`

#echo $ERRORE_LOW_HIGH

if [ $ERRORE_LOW_HIGH -gt 0 ] ; then
   echo Errore nella query per la determinazione della size attuale del device
   exit 1;
fi

SIZE_ATTUALE_DEVICE=`grep LOWHIGH /tmp/db-ampliamento-dati-lowhigh | awk '{ print ($3 - $2 + 1)*2048/1048576; }'`

echo "Size attuale device: " $SIZE_ATTUALE_DEVICE "MB"

# La size attuale piu' la size dell'ampliamento fanno la size finale del device
SIZE_FINALE_DEVICE=`echo $SIZE_ATTUALE_DEVICE $SIZE | awk '{ print ($1 + $2); }'`

echo "Size finale device: " $SIZE_FINALE_DEVICE "MB"

# Eseguo il resize del device e l'alter database per ampliarlo

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF > /tmp/db-ampliamento-dati-resize
disk resize name = "$DEVICE_DA_AMPLIARE", size ="${SIZE}M"
if @@error != 0 select 'ERRORERESIZE'
go
alter database $NOMEDB on $DEVICE_DA_AMPLIARE = "${SIZE_FINALE_DEVICE}M"
if @@error != 0 select 'ERRORERESIZE'
go
exit
EOF

ERRORE_RESIZE=`grep ERRORERESIZE /tmp/db-ampliamento-dati-resize | wc -l`

#cat /tmp/db-ampliamento-dati-resize

if [ $ERRORE_RESIZE -gt 0 ] ; then
   echo "Errore nel resize o nell'alter del db" 
   exit 1;
fi

echo " "
echo Operazione effettuata
echo Ampliamento eseguito di $SIZE MB
echo " "

exit


