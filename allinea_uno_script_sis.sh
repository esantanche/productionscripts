#!/bin/sh

scp $1 mx2-test-1:/sis
scp $1 mx2-pridb:/sis
scp $1 mx1-secdb:/sis

