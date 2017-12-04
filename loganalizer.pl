#!/usr/bin/perl -w

#****P* Loganalizing/loganalizer.pl
# NAME
#    loganalizer.pl Analisi del log dell'ASE e segnalazione dei soli errori critici
# USAGE
#    Si tratta di un processo sempre attivo che viene eventualmente riavviato 
#    dallo script loganalizer-runner.sh in caso di crash.
# PURPOSE
#    Lo script legge il log dell'ASE rimanendo in attesa delle righe man mano aggiunte
#    come viene fatto dal comando 'tail -f'. Lo script è in grado di accorgersi se
#    il log viene troncato come avviene periodicamente ad opera dello script 
#    logtruncator.sh.
#    Vengono segnalati gli errori che appaiono nel log ovvero le righe contenenti la stringa
#    'Error:'. Vengono ignorati alcuni errori di bassa severità e che appaiono spesso.
#    Attualmente si tratta degli errori 1608 e 1621.
#    Viene segnalato l'avvio dell'ASE senza le funzionalità opzionali (messaggio
#    'Server is booting with all the option features disabled') cosa che può avvenire
#    per malfunzionamenti del License Manager.
# HISTORY
#    Versione iniziale.
# INPUTS
#    Va dato come parametro sulla linea comando il path completo del file di log dell'ASE
# OUTPUT
#    Per ogni errore trovato nel log lo script crea un file contenente la riga dell'errore
#    e le ultime 10 righe del log stesso per fornire così un contesto all'errore utile
#    per la valutazione dello stesso senza dover consultare il log. Tale file viene 
#    passato allo script centro_unificato_messaggi.sh che segnala l'errore con 
#    modalità standardizzate per tutti gli script.
# RETURN VALUE
#    Non ci sono valori di ritorno.
# EXAMPLE
#    Lo script viene lanciato dallo script loganalizer-runner.sh che contiene appunto un
#    esempio di utilizzo dello script.
# NOTES
#    Lo script loganalizer-runner.sh che avvia questo viene a sua volta richiamato dal
#    crontab dell'utente sybase.
#    All'avvio lo script si posiziona sull'ultima riga del log per cui se lo script
#    viene killato e poi riavviato mentre l'ASE è in funzione, perderà le righe scritte
#    nel log nel frattempo.
#    Se lo script non trova il log, attende che venga creato. Questo è utile nei
#    casi di troncamento del log in cui il vecchio log viene rinominato e si lascia
#    che l'ASE crei quello nuovo.
# ERRORS
#    Sono segnalati alcuni errori mediante messaggi in stdout. Tali errori vengono di fatto
#    ignorati perché lo script è eseguito in background (viene lanciato con il nohup).
#    Si tratta in ogni caso di situazioni di errore scarsamente probabili.
# SEE ALSO
#    loganalizer-runner.sh, centro_unificato_messaggi.sh 
#***

#$path_file_errori = "/nagios_reps/Errori_nel_log_ASE";
$path_file_errori = "/tmp/.oggi/errore_log_ASE";

use IO::File;

# Come argomento prendo il path del log ? Si me lo passera' uno script di lancio apposito
$path_file = $ARGV[0];
if (!defined($path_file)) {
   print "usage: perl $0 <path del log>\n\n";
   exit;
}

#sub catch_zap {
#   my $signame = shift;
#   $shucks++;
#   die "Somebody sent me a SIG$signame";
#}
#$SIG{INT} = \&catch_zap;  # best strategy

sub analizza_riga {
   my $riga = shift;
   #print "riga ", $riga;
   $trovato_err = (/Error:/ && !/1608/ && !/1621/);
   $trovato_err ||= (/Server is booting with all the option features disabled./);
   #$trovato_err ||= (/Deadlock/);
   if ($trovato_err) {
      sleep 10;
      $err_file = new IO::File;
      $err_file->open($path_file_errori,"w");
      print $err_file "__________________\n";
      print $err_file $_;
      print $err_file "__________________\n";
      close $err_file;

      system("tail -10 " . $path_file . " >> " . $path_file_errori);
      system("centro_unificato_messaggi.sh LOGANLZ ASE 1 0 0 " . $path_file_errori);

   }
}

$attesa=10;

# fare in modo che se non trovo il file aspetto che appia
# una function che apra e chiuda
undef($FILE_LOG);

for (;;) {
   if (!open($FILE_LOG,"<",$path_file)) {
      sleep($attesa);
      next;
   } else {
      # Seek end of file the first time
      seek($FILE_LOG, 0, 2);
      last;
   }
}

for (;;) {

   if (!defined($FILE_LOG)) {
      #print "FILE_LOG non definito, vado con la open\n";
      if (!open($FILE_LOG,"<",$path_file)) {
         #print "open fallita\n";
         undef($FILE_LOG);
         sleep($attesa);
         next;
      } else {
         seek($FILE_LOG, 0, 0);
      }
   }

   #print "dopo open\n";

   for ($curpos = tell($FILE_LOG); $_ = <$FILE_LOG>; $curpos = tell($FILE_LOG)) {
      # search for some stuff and put it into files
      # Work the lines here (put them out)
      ### chiamare funzione che analizza la riga
      analizza_riga($_);
   }

   # SLEEP
   sleep($attesa);

   if (!seek($FILE_LOG, $curpos, 0)) {
      print "seek non riuscito in smart_tail\n";
   }

   # Verifing if anyone changed name to the file
   ($dev,$ino_actual,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($path_file);
   ($dev,$ino       ,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($FILE_LOG);

   #print "   -  curpos ",$curpos," size ",$size," ino ",$ino," ctime ",$ctime,"\n";

   if (defined($ino_actual)) {
      if ($ino != $ino_actual) {
         # bisogna leggere il leggibile e chiudere e riaprire
         print "attenzione rename !!! ",$ino_actual,"\n";
         for ($curpos = tell($FILE_LOG); $_ = <$FILE_LOG>; $curpos = tell($FILE_LOG)) {
            # search for some stuff and put it into files
            # Work the lines here (put them out)
            analizza_riga($_);
         }
         close($FILE_LOG);
         undef($FILE_LOG);
      } else {
         if ($size < $curpos) {
            seek($FILE_LOG, 0, 0);
         }
      }
   } else {
      # anche qui chiudere e riaprire
      #print "ino_actual non definito\n";
      for ($curpos = tell($FILE_LOG); $_ = <$FILE_LOG>; $curpos = tell($FILE_LOG)) {
         # search for some stuff and put it into files
         # Work the lines here (put them out)
         analizza_riga($_);
      }
      close($FILE_LOG);
      undef($FILE_LOG);

   }

}

close($FILE_LOG);

exit 0;

