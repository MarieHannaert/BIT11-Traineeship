#!/bin/bash
#loop over raw files
mkdir output_fastqc
for g in `ls *.fq.gz | awk 'BEGIN{FS=".fq.gz"}{print $1}'`
do
    echo "quality control on $g with fastqc"
    fastqc -o output_fastqc --extract "$g".fq.gz #loop over read files
done
echo
echo "Finished fastqc"
