#!/bin/bash
# This script will perform the complete illumina pipeline so that the pipeline can be perfomed on multiple samples and in one step 
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



##checking for parameters
function usage(){
	errorString="Running this Illumina pipeline script requires 4 parameters:\n
    1. Path of the folder with fastq.gz files.\n
    2. Name of the output folder.\n
    3. Type of compression (gz or bz2)\n
    4. Number of threads to use.";

	echo -e ${errorString};
	exit 1;
}

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
cd $DIR

#making the output directory 
mkdir -p $OUT

#making a log file 
touch "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#adding the user of the script that day to the log file 
echo "The user of" $DATE_TIME "is:" $USER | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
# adding the versions of the tools that are used 
echo "the version that are used are:" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#I will fill this in while writing the script 
fastqc -v | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda activate multiqc
conda list | grep multiqc | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda deactivate
fastp -v | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log

echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#adding the command to the log file
echo "the command that was used is:"| tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "complete_illuminapipeline.sh" $1 $2 $3 $4 |tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "This was performed in the following directory: $START_DIR" |tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log

#checking which file format
#if bz then reformat to gz 
#if gz then continue
#if something else then exit, because needs to be gz of bz2
echo "checking fileformat and reformat if needed" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
if [[ $3 == "bz2" ]]; then
    #decompress bz2
    echo "files are reformated to gz" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    pbzip2 -dk -p32 *fq.bz2 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    #compress to gz
    pigz *.fq
elif [[ $3 == "gz" ]]; then
    echo "files are gz, so that's fine" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log

elif [[ $3 != "gz" ]] | [[ $3 != "bz2" ]]; then
    echo "This is not a correct file format, it can only be gz or bz2" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    exit 1 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
fi

#performing fastqc on the gz samples 
echo Performing fastqc | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
mkdir -p "$OUT"/fastqc
fastqc -t 32 *.gz --extract -o "$OUT"/fastqc 
#activating the mamba env 
#conda init 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log

conda activate multiqc 
#perfomring the multiqc on the fastqc samples
cd $OUT
echo performing multiqc | tee -a "$DATE_TIME"_Illuminapipeline.log
multiqc fastqc 2>> "$DATE_TIME"_Illuminapipeline.log
echo removing fastqc/ | tee -a "$DATE_TIME"_Illuminapipeline.log
rm -rd fastqc/ 2>> "$DATE_TIME"_Illuminapipeline.log
#deactivating the mamba env
conda deactivate

#now perfroming fastp on the samples
#going back up to the samples
cd ..
#making a folder for the trimmed samples
mkdir -p "$OUT"/fastp
touch "$OUT"/fastp/"$DATE_TIME"_fastp.log
#loop over read files
for g in `ls *_1.fq.gz | awk 'BEGIN{FS="_1.fq.gz"}{print $1}'`
do
    echo "Working on trimming genome $g with fastp" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    fastp -w 32 -i "$g"_1.fq.gz -I "$g"_2.fq.gz -o "$OUT"/fastp/"$g"_1.fq.gz -O "$OUT"/fastp/"$g"_2.fq.gz -h "$OUT"/fastp/"$g"_fastp.html -j "$OUT"/fastp/"$g"_fastp.json --detect_adapter_for_pe 2>> "$OUT"/fastp/"$DATE_TIME"_fastp.log
done
echo
echo "Finished trimming" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log


#Shovill part
conda activate shovill
#making a folder for the output 
mkdir -p "$OUT"/shovill
#making a log file for the shovill
touch "$OUT"/shovill/"$DATE_TIME"_shovill.log
#moving in to the file with the needed samples
cd "$OUT"/fastp/

FILES=(*_1.fq.gz)
#loop over all files in $FILES and do the assembly for each of the files
for f in "${FILES[@]}" 
do 
	SAMPLE=`basename $f _1.fq.gz`  	#extract the basename from the file and store it in the variable SAMPLE

	#run Shovill
	shovill --R1 "$SAMPLE"_1.fq.gz --R2 "$SAMPLE"_2.fq.gz --cpus 16 --ram 16 --minlen 500 --trim -outdir ../shovill/"$SAMPLE"/ 2>> ../shovill/"$DATE_TIME"_shovill.log
	echo "==========================================================================" >> ../shovill/"$DATE_TIME"_shovill.log
	echo Assembly "$SAMPLE" done ! | tee -a ../"$DATE_TIME"_Illuminapipeline.log
done
#moving back to the main directory
cd ..
conda deactivate



