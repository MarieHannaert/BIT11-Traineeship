#!/bin/bash
# This script will perform the complete long-read pipeline so that the pipeline can be perfomed on multiple samples and in one step 
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

function usage(){
    errorString="Running this Illumina pipeline script requires 4 parameters:\n
    1. Path of the folder with fastq.gz files.\n
    2. Name of the output folder.\n
    3. Type of compression (gz or bz2)\n
    4. Number of threads to use.";

    echo -e "${errorString}";
    exit 1;
}

if [ "$#" -ne 4 ]; then
  usage
fi

DIR=$1
OUT=$2
START_DIR=$(pwd)
DATE_TIME=$(date '+%Y-%m-%d_%H-%M')

#part about nanoplot
mamba activate nanoplot 
mkdir -p "$OUT"/01_nanoplot
NanoPlot -t 2 --fastq "$DIR"/*.fq.gz -o "$OUT"/01_nanoplot --maxlength 40000 --plots --legacy hex dot 
mamba deactivate

#filtlong 
#Porechop ABI
#flye 
#Racon
#skANI
#quast
# quast summary
# xlsx
# beeswarmvisualisation
