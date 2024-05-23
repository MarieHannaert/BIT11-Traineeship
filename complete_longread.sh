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
    errorString="Running this long-read pipeline script requires 4 parameters:\n
    1. Path of the folder with fastq.gz files.\n
    2. Name of the output folder.\n
    3. Type of compression (gz or bz2)\n
    4. Number of threads to use.";

    echo -e "${errorString}";
    exit 1;
}

function Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "Syntax: scriptTemplate [-g|h|v|u]"
   echo "options:"
   echo "g     Print the license notification."
   echo "h     Print this Help."
   echo "v     Print version of script and exit."
   echo "u     Print usage of script and exit."
}

while getopts ":gvuh" option; do
    case $option in
        h) # display Help
            Help
            exit;;
        g) # Print the license notification
            echo "Copyright 2024 Marie Hannaert (ILVO) 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
            exit;;
        v) # Print version of script and exit
            echo "complete_longread script version 1.0"
            exit;;
        u) # display usage
            usage;;
        \?) # Invalid option
            usage;;
    esac
done

if [ "$#" -ne 4 ]; then
  usage
fi



#defining the needed parameters 
DIR=$1
OUT=$2
START_DIR=$(pwd)
DATE_TIME=$(date '+%Y-%m-%d_%H-%M')

#checking if the input directory exist 
while true; do
  echo "The given input directory is: $1"

  if [ -d "$1" ]; then
    echo "$1 exists."
    break
  else
    echo "$1 does not exist. Please enter a correct path:"
    read -r DIR
    if [ -d "$DIR" ]; then
      # If the user entered a valid directory path, use it instead of the original argument
      set -- "$DIR"
    fi
  fi
done

#going to the input directory
cd "$DIR"

#making the output directory 
mkdir -p "$OUT"

#making a log file 
touch "$OUT"/"$DATE_TIME"_Longreadpipeline.log
#adding the user of the script that day to the log file 
echo "The user of" "$DATE_TIME" "is:" "$USER" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
# adding the versions of the tools that are used 
echo "the version that are used are:" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
#I will fill this in while writing the script
conda activate nanoplot
conda list | grep nanoplot | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
conda deactivate
conda activate filtlong
conda list | grep filtlong | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
conda deactivate
conda activate porechop_abi
conda list | grep porechop_abi | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
conda deactivate
conda activate flye
conda list | grep flye | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
conda deactivate
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
#adding the command to the log file
echo "the command that was used is:"| tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
echo "complete_longread.sh" "$1" "$2" "$3" "$4" |tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
echo "This was performed in the following directory:$START_DIR" |tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log

echo "The analysis started at" "$(date '+%Y/%m/%d_%H:%M')" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
#checking which file format
#if bz then reformat to gz 
#if gz then continue
#if something else then exit, because needs to be gz of bz2
echo "checking fileformat and reformat if needed at $(date '+%H:%M')" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
if [[ $3 == "bz2" ]]; then
    #decompress bz2
    echo "files are reformated to gz" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
    pbzip2 -dk -p32 *fq.bz2 2>> "$OUT"/"$DATE_TIME"_Longreadpipeline.log
    #compress to gz
    pigz *.fq
    #rm *fq.bz2 
elif [[ $3 == "gz" ]]; then
    echo "files are gz, so that's fine" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log

elif [[ $3 != "gz" ]] && [[ $3 != "bz2" ]]; then
    echo "This is not a correct file format, it can only be gz or bz2" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
    exit 1 2>> "$OUT"/"$DATE_TIME"_Longreadpipeline.log
fi
echo "File reformatting done and starting nanoplot at $(date '+%H:%M')" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log


#part about nanoplot
conda activate nanoplot 
echo Performing nanoplot | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
mkdir -p "$OUT"/01_nanoplot
NanoPlot -t 2 --fastq *.fq.gz -o "$OUT"/01_nanoplot --maxlength 40000 --plots --legacy hex dot 2>> "$OUT"/01_nanoplot/"$DATE_TIME"_nanoplot.log
conda deactivate

echo "nanoplot done, starting filtlong at $(date '+%H:%M')"| tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log

#filtlong 
conda activate filtlong
echo Performing filtlong | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
mkdir -p "$OUT"/02_filtlong 
for sample in `ls *.fq.gz | awk 'BEGIN{FS=".fq.gz"}{print $1}'`; do filtlong --min_length 1000 --target_bases 540000000 "$sample".fq.gz |  gzip > "$OUT"/02_filtlong/"$sample"_1000bp_100X.fq.gz ; done 2>> "$OUT"/02_filtlong/"$DATE_TIME"_filtlong.log
conda deactivate 

#Porechop ABI
conda activate porechop_abi
echo Performing Porechop_ABI | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
mkdir -p "$OUT"/03_porechopABI
pigz -d *.fq.gz
for sample in `ls *.fq | awk 'BEGIN{FS=".fq"}{print $1}'`; do porechop_abi -abi -t 32 -v 2 -i $sample.fq -o "$OUT"/03_porechopABI/"$sample"_trimmed.fq ; done  | tee "$OUT"/03_porechopABI/"$DATE_TIME"_porechopABI.log
conda deactivate 

#flye 
conda activate flye
echo reformatting fq to fast | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log

for sample in `ls "$OUT"/03_porechopABI/*_trimmed.fq | awk 'BEGIN{FS="_trimmed.fq"}{print $1}'`;
do cat "$sample"_trimmed.fq | awk '{if(NR%4==1) {printf(">%s\n",substr($0,2));} else if(NR%4==2) print;}' > "$sample"_OUTPUT.fasta;
done 

echo Performing Flye | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
mkdir -p "$OUT"/04_flye
cd 03_porechopABI/

for sample in `ls *_OUTPUT.fasta | awk 'BEGIN{FS="_OUTPUT.fasta"}{print $1}'`;
do flye --asm-coverage 50 --genome-size 5.4g --nano-hq "$sample"_OUTPUT.fasta --out-dir "$OUT"/04_flye/flye_out_"$sample" --threads 32 --iterations 1 --scaffold;
done 
cd ..
conda deactivate 

#Racon
#skANI
#quast
#quast summary
#xlsx
#beeswarmvisualisation
