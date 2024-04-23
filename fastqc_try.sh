#!/bin/bash
#loop over raw files

for g in `ls *.fq.gz | awk 'BEGIN{FS=".fq.gz"}{print $1}'`
do
    echo "quality control on $g with fastqc"
    fastqc -o /home/mhannaert/01_fastqc --extract "$g".fq.gz #loop over read files
done
echo
echo "Finished fastqc"
