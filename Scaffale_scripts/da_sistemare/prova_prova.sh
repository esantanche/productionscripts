#!/bin/bash

Lista()
{

   echo $1
   find $1/* -prune -mtime -60 -ls

#dir_da_vedere


}

Lista "/tmp"

echo $0

