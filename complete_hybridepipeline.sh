#!/bin/bash
# This script will perform the complete hybride pipeline so that the pipeline can be perfomed on multiple samples and in one step 
#This will combine short read data and long read data
#when this script is completed, it needs to become a snakemake pipeline
#This script is meant to be performed on the server

DIR=$1
OUT=$2
START_DIR=$(pwd)
DATE_TIME=$(date '+%Y-%m-%d_%H-%M')

#going to the input directory
cd "$DIR"

#making the output directory 
mkdir -p "$OUT"

if [[ $3 == "bz2" ]]; then
    #decompress bz2
    echo "files are reformated to gz" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
    pbzip2 -dk -p32 *fq.bz2 2>> "$OUT"/"$DATE_TIME"_Hybridepipeline.log
    #compress to gz
    pigz *.fq
    #rm *fq.bz2 
elif [[ $3 == "gz" ]]; then
    echo "files are gz, so that's fine" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log

elif [[ $3 != "gz" ]] && [[ $3 != "bz2" ]]; then
    echo "This is not a correct file format, it can only be gz or bz2" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
    exit 1 2>> "$OUT"/"$DATE_TIME"_Hybridepipeline.log
fi

#CSV part
touch "$OUT"/input_table_hybracter.csv

for sample in *1.fq.gz; do
    base_name=$(basename -- "$sample" _1.fq.gz)
    echo "${base_name}_hybrid,${base_name}.fq.gz,${base_name}_1.fq.gz,${base_name}_2.fq.gz" >> "$OUT"/input_table_hybracter.csv
done

