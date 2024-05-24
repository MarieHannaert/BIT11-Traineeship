#!/bin/bash
# This script will perform the complete hybride pipeline so that the pipeline can be perfomed on multiple samples and in one step 
#This will combine short read data and long read data
#when this script is completed, it needs to become a snakemake pipeline
#This script is meant to be performed on the server

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

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

#asking chromosome size 
echo "Enter chromosome size (90%) as an intiger (e.g.2500000):"
read CHROMOSOME_SIZE


#CSV part
echo "Making input CSV for Hybracter"| tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
touch "$OUT"/input_table_hybracter.csv

for sample in *1.fq.gz; do
    base_name=$(basename -- "$sample" _1.fq.gz)
    echo -e "${base_name}_hybrid,${base_name}.fq.gz,"$CHROMOSOME_SIZE",${base_name}_1.fq.gz,${base_name}_2.fq.gz" >> "$OUT"/input_table_hybracter.csv
done

#Hybracter
echo "Performing Hybracter"| tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
mkdir -p "$OUT"/01_hybracter
conda activate hybracterENV
hybracter hybrid -i "$OUT"/input_table_hybracter.csv -o "$OUT"/01_hybracter/ -t "$4"
conda deactivate 