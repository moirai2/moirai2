#!/bin/sh
#$ -i input
#$ -r output
output=`wc -l $input`
