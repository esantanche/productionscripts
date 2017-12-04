#!/usr/bin/perl -w

# smart_tail v 0.1 
# 2006.12.05-21:30:57 rilasciato v 0.1

use IO::File;

# Come argomento ricevo il path del file da monitorare, tipicamente un file di log
$path_file=$ARGV[0];
if (!defined($path_file)) {
   print "usage: perl $0 <path del log>\n\n";
   exit;
}

    sub catch_zap {
        my $signame = shift;
        $shucks++;
        die "Somebody sent me a SIG$signame";
    }
    $SIG{INT} = \&catch_zap;  # best strategy


$attesa=2;

# fare in modo che senon trovo il file aspetto che appia
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
   for (;;) {
        undef $!;
        unless (defined( $line = <$FILE_LOG> )) {
            die $! if $!;
            last; # reached EOF
        }
        # ...
        print tell($FILE_LOG)," ",$line;
    }
    sleep(10);
}

close($FILE_LOG);

exit;

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
      print $_;
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
         #print "attenzione rename !!! ",$ino_actual,"\n";
         for ($curpos = tell($FILE_LOG); $_ = <$FILE_LOG>; $curpos = tell($FILE_LOG)) {
            # search for some stuff and put it into files
            # Work the lines here (put them out)
            print $_;
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
         print $_;
      }
      close($FILE_LOG);
      undef($FILE_LOG);
   }

}

close($FILE_LOG);

exit 0

