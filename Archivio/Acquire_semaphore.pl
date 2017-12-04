#!/usr/bin/perl -w

# TBD tradurre in inglese

# Prova di estensione snmpd persistente
# ???? Al get della prima chiave si genera un file che poi viene usato
# per le successive letture


use IPC::SysV qw(IPC_NOWAIT IPC_RMID SEM_UNDO IPC_CREAT);
use IPC::Semaphore;

# This script will try to lock a semaphore exiting if it
# is already locked by another process

# The semaphore will be released automatically by a process
# even if it is killed by a -9 signal because of the SEM_UNDO
# option used in locking it

# The first command line parameter is the semaphore key

#$IPC_KEY = 0xF78;
#$id = semget($IPC_KEY, 1, 0666 | IPC_CREAT ) || die "$!";
#print "sem key $IPC_KEY id $id\n";

#exit;

# TBD check arg presence

$command=$ARGV[1];

$IPC_KEY = $ARGV[0];
$sem = new IPC::Semaphore($IPC_KEY, 0, 0);
if (!defined($sem)) {
   # TBD create the sem
   print "TRC: sem not found\n";
   $sem = new IPC::Semaphore($IPC_KEY, 1, 0666 | IPC_CREAT);
   if (!defined($sem)) {
      # TBD can't create the sem!
      print "ERR: can't create the sem\n";
   }
}

if($sem->op( 0, 0, IPC_NOWAIT | SEM_UNDO, 0, 1, IPC_NOWAIT | SEM_UNDO )) {
   $myERRNO=$!;
   $myERR=$?;
   print "TRC: sem acquired <$myERR> <$myERRNO> \n";
   # TBD return code to be setted
} else {
   print "TRC: sem not acquired\n";
   # TBD return code to be setted
   exit;
}

system($command);

# TBD destroy the sem

exit;


#$pid=$sem->getpid(0);
#print "pid ",$pid,"\n";


#$IPC_KEY = 0xF78;
#$id = semget($IPC_KEY,  0 , 0 );
#die if !defined($id);

#$arr_sem=pack("s!",(0)x1);
#semctl($id,0,GETPID,$arr_sem);

#print 

$semnum = 0;
$semflag = IPC_NOWAIT;

# ’take’ semaphore
# wait for semaphore to be zero
$semop = 0;
$opstring1 = pack("s!s!s!", $semnum, $semop, $semflag);

# pack("s!",(0)x$nsem)

if (!semop($id,$opstring1)) {
   print "Semaforo rosso! non posso proseguire!\n";
   print "In realtà devo vedere se il proprietario del semaforo\n";
   print "è ancora attivo\n";
   
   #semctl($id,0,IPC_RMID,0); # questo cancella il semaforo
   exit;
}
$ERR=$?;
$OUT=$!;

print "ERR: ",$ERR,"\n";
print "OUT: ",$OUT,"\n";

#exit;
# || die "($?) $!";

# Increment the semaphore count
$semnum = 0;
$semflag = IPC_NOWAIT | SEM_UNDO;
$semop = 1;
$opstring2 = pack("s!s!s!", $semnum, $semop,  $semflag);

semop($id,$opstring2) || die "($?) $!";

sleep 300;



