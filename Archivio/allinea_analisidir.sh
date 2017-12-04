#!/bin/sh

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

scp $UTILITY_DIR/analisi-dir/* mx2-test-1:/sybase/utility/analisi-dir
scp $UTILITY_DIR/analisi-dir/* mx2-pridb:/sybase/utility/analisi-dir
scp $UTILITY_DIR/analisi-dir/* mx1-secdb:/sybase/utility/analisi-dir

