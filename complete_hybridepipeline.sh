#!/bin/bash
# This script will perform the complete hybride pipeline so that the pipeline can be perfomed on multiple samples and in one step 
#This will combine short read data and long read data
#when this script is completed, it needs to become a snakemake pipeline
#This script is meant to be performed on the server

DIR=$1
OUT=$2

#going to the input directory
cd "$DIR"

#making the output directory 
mkdir -p "$OUT"

#CSV part
touch "$OUT"/input_table_hybracter.csv

for sample in $(ls *.fq.gz | awk 'BEGIN{FS=".fq.*"}{print $1}');
do echo "$sample"_hybrid,"$sample".fq.gz, ,"$sample"_1.fq.gz,"$sample"_2.fq.gz >> "$OUT"/input_table_hybracter.csv;
done

