#!/usr/bin/perl -w

$path_file_errori = "/nagios_reps/Errore_avvio_script_in_crontab";

use IO::File;

# Inserisco cablato qui il path del log del demone di cron

$PATH_LOG = "/var/adm/cron/log";

#if (!defined($PATH_LOG)) {
#   print "usage: perl $0 <path del log>\n\n";
#   exit;
#}

$log_file = new IO::File;

if (!$log_file->open("tail -f " . $PATH_LOG . " |")) {
   print "Non riesco ad aprire il log del crond\n";
   print "(by $0)\n";
   exit 1;
}
while (<$log_file>) { 
   if (/^\!/ && !/cron.*start/) {
      $err_file = new IO::File;
      $err_file->open($path_file_errori,"a");
      print $err_file $_;
      close $err_file;
   }
};
close $log_file;

exit
