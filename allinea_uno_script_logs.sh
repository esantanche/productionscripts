#!/bin/sh

scp $1 mx2-test-1:/sybase/utility/logs
scp $1 mx2-pridb:/sybase/utility/logs
scp $1 mx1-secdb:/sybase/utility/logs

