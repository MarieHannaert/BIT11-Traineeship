# Script long read pipeline
In this README you can find all the steps I took to make the script for the longread pipeline. 
I will do this based on **/home/genomics/mhannaert/test_longreadpipeline**
## Info from supervisor
basecalling is already done, so I need to start with the nanoplot qc. I also need to add racon so that these reads can be polished. 

To make this script I will also base me on the **/home/genomics/mhannaert/scripts/complete_illuminapipeline.sh**

## The steps that need to be taken/design 
- nanoplot qc 
- filtlong 
- porechop ABI
- flye
- racon 
- quast 
- skani 

I will also add the extra parts for summaries and visualisations. 

## the script 
### start + nanoplot qc 
````
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

````
This is the first part I added. 
I will test this part before I go on: 
````
File provided doesn't exist or the path is incorrect: data/mini_longread//*/*.fq.gz
````
## further on nanoplot 
So I asked my supervisor about the input, because that is were I was stuck yesterday, the input will just be sample_fq.bz2 so that is were I'm going to focus on. 

I made this: 
````
#part about nanoplot
conda activate nanoplot 
echo Performing nanoplot | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
mkdir -p "$OUT"/01_nanoplot
NanoPlot -t 2 --fastq *.fq.gz -o "$OUT"/01_nanoplot --maxlength 40000 --plots --legacy hex dot 2>> "$OUT"/"$DATE_TIME"_Longreadpipeline.log
conda deactivate
````
I tested it and it worked. 

## Filtlong 
I made the following part:
````
#filtlong 
echo Performing filtlong | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
mkdir -p "$OUT"/02_filtlong 
for sample in `ls *.fq.gz | awk 'BEGIN{FS=".fq.gz"}{print $1}'`; do filtlong --min_length 1000 --target_bases 540000000 "$sample".fq.gz |  gzip > "$OUT"/02_filtlong/"$sample"_1000bp_100X.fq.gz ; done 2>> "$OUT"/"$DATE_TIME"_Longreadpipeline.log
````
I got an error that the command was not found, maybe it is a mamba env. 
Indeed. 
so made the following change:
````
conda activate filtlong
echo Performing filtlong | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
mkdir -p "$OUT"/02_filtlong 
for sample in `ls *.fq.gz | awk 'BEGIN{FS=".fq.gz"}{print $1}'`; do filtlong --min_length 1000 --target_bases 540000000 "$sample".fq.gz |  gzip > "$OUT"/02_filtlong/"$sample"_1000bp_100X.fq.gz ; done 2>> "$OUT"/"$DATE_TIME"_Longreadpipeline.log
conda deactivate 
````
run again: 
This time it worked, but I removed the "2>>" because it was to much output for the log file. maybe I will make a personal logfile for filtlong. 

## Porechop ABI
This is my start: 
````
#Porechop ABI
conda activate porechop_abi
echo Performing Porechop_ABI | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
mkdir -p "$OUT"/03_porechopABI
pigz -d *.fq.gz
for sample in `ls *.fq | awk 'BEGIN{FS=".fq"}{print $1}'`; do porechop_abi -abi -t 32 -v 2 -i $sample.fq -o "$OUT"/03_porechopABI/"$sample"_trimmed.fq ; done  | tee "$OUT"/03_porechopABI/"$DATE_TIME"_porechopABI.log
conda deactivate
````
Now I test it: 
It worked I got some nice results 

## Flye 
I first must reformat my samples from fq to fasta: 
````
echo reformatting fq to fast | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log

for sample in `ls "$OUT"/03_porechopABI/*_trimmed.fq | awk 'BEGIN{FS="_trimmed.fq"}{print $1}'`;
do cat "$sample"_trimmed.fq | awk '{if(NR%4==1) {printf(">%s\n",substr($0,2));} else if(NR%4==2) print;}' > "$sample"_OUTPUT.fasta;
done
````
I tried this command just in the terminal and it worked, it gave nice output. 

Now I will add the flye part: 
````

for sample in `ls *_OUTPUT.fasta | awk 'BEGIN{FS="_OUTPUT.fasta"}{print $1}'`;
do flye --asm-coverage 50 --genome-size 5.4g --nano-hq "$sample"_OUTPUT.fasta --out-dir "$OUT"/04_flye/flye_out_"$sample" --threads 32 --iterations 1 --scaffold;
done 2>> "$OUT"/04_flye/"$DATE_TIME"_flye.log
cd ..
conda deactivate 
````

To test this I runned it in the **03_porechopABI/** with the following command: 
````
 for sample in `ls *_OUTPUT.fasta | awk 'BEGIN{FS="_OUTPUT.fasta"}{print $1}'`;
do flye --asm-coverage 50 --genome-size 5.4g --nano-hq "$sample"_OUTPUT.fasta --out-dir ../04_flye/flye_out_"$sample" --threads 32 --iterations 1 --scaffold;
done
````
i did this because otherwise it needs to run again all the steps, I will run it over night in complete, so that I don't have to wait too long on results and go on with the other steps. 

The result of this run: 
is 2 directories for each sample. SO the command worked. 
I removed the log at the end of the command because flye makes it's own log files. 
## Racon
## SkANI
## Quast
## Quast summary
## Xlsx
## Beeswarmvisualisation