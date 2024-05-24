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
touch "$OUT"/"$DATE_TIME"_Hybridepipeline.log
#adding the user of the script that day to the log file 
echo "The user of" "$DATE_TIME" "is:" "$USER" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
# adding the versions of the tools that are used 
echo "the version that are used are:" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
#I will fill this in while writing the script
conda activate hybracterENV
conda list | grep hybracterENV | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
conda deactivate
conda activate skani 
conda list | grep skani | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
conda deactivate 
conda activate quast
conda list | grep quast | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
conda deactivate
conda activate busco
conda list | grep busco | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
conda deactivate
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
#adding the command to the log file
echo "the command that was used is:"| tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
echo "complete_longread.sh" "$1" "$2" "$3" "$4" |tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
echo "This was performed in the following directory:$START_DIR" |tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
echo "The analysis started at" "$(date '+%Y/%m/%d_%H:%M')" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log

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

echo "asking for chromosome size  $(date '+%H:%M')" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
#asking chromosome size 
echo "Enter chromosome size (90%) as an intiger (e.g.2500000):"
read CHROMOSOME_SIZE
echo "The chromosome size for 90% of the chromosome that was give is: $CHROMOSOME_SIZE" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log


#CSV part
echo "Making input CSV for Hybracter at $(date '+%H:%M')"| tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
touch "$OUT"/input_table_hybracter.csv

for sample in *1.fq.gz; do
    base_name=$(basename -- "$sample" _1.fq.gz)
    echo -e "${base_name}_hybrid,${base_name}.fq.gz,"$CHROMOSOME_SIZE",${base_name}_1.fq.gz,${base_name}_2.fq.gz" >> "$OUT"/input_table_hybracter.csv
done

#Hybracter
echo "Performing Hybracter at $(date '+%H:%M')"| tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
mkdir -p "$OUT"/01_hybracter
conda activate hybracterENV
hybracter hybrid -i "$OUT"/input_table_hybracter.csv -o "$OUT"/01_hybracter/ -t "$4"
conda deactivate 
echo "Done with Hybracter at $(date '+%H:%M')"| tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log

#checking complete or incomplete 
if [ -d "$OUT"/01_hybracter/FINAL_OUTPUT/incomplete ]; then
    STATUS="incomplete"
else
    STATUS="complete"
fi

# performing skani
conda activate skani 
#making a directory and a log file 
mkdir -p "$OUT"/02_skani 
touch "$OUT"/02_skani/"$DATE_TIME"_skani.log
echo "performing skani at $(date '+%H:%M')" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
#command to perform skani on the 
skani search "$OUT"/01_hybracter/FINAL_OUTPUT/"$STATUS"/*_hybrid_final.fasta -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o 02_skani/skani_results_file.txt -t 24 -n 1 2>> "$OUT"/02_skani/"$DATE_TIME"_skani.log
conda deactivate 

echo "Finished skANI and starting Quast at $(date '+%H:%M')" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log

#performing quast
conda activate quast

echo "performing quast" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
for f in "$OUT"/01_hybracter/FINAL_OUTPUT/"$STATUS"/*_hybrid_final.fasta; do quast.py "$f" -o "$OUT"/03_quast/"$f";done 

# Create a file to store the QUAST summary table
echo "making a summary of quast data" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
touch "$OUT"/03_quast/quast_summary_table.txt

# Add the header to the summary table
echo -e "Assembly\tcontigs (>= 0 bp)\tcontigs (>= 1000 bp)\tcontigs (>= 5000 bp)\tcontigs (>= 10000 bp)\tcontigs (>= 25000 bp)\tcontigs (>= 50000 bp)\tTotal length (>= 0 bp)\tTotal length (>= 1000 bp)\tTotal length (>= 5000 bp)\tTotal length (>= 10000 bp)\tTotal length (>= 25000 bp)\tTotal length (>= 50000 bp)\tcontigs\tLargest contig\tTotal length\tGC (%)\tN50\tN90\tauN\tL50\tL90\tN's per 100 kbp" >> "$OUT"/03_quast/quast_summary_table.txt

# Initialize a counter
counter=1

# Loop over all the transposed_report.tsv files and read them
for file in $(find -type f -name "transposed_report.tsv"); do
    # Show progress
    echo "Processing file: $counter"

    # Add the content of each file to the summary table (excluding the header)
    tail -n +2 "$file" >> "$OUT"/03_quast/quast_summary_table.txt

    # Increment the counter
    counter=$((counter+1))
done

conda deactivate

#Busco part
conda activate busco
echo "performing busco $(date '+%H:%M')" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
for sample in $(ls "$OUT"/01_hybracter/FINAL_OUTPUT/"$STATUS"/*_hybrid_final.fasta | awk 'BEGIN{FS="_hybrid_final.fasta"}{print $1}'); 
do busco -i "$sample"_hybrid_final.fasta -o "$OUT"/04_busco/"$sample" -m genome --auto-lineage-prok -c 32 ; done

#extra busco part
#PLOT SUMMARY of busco
mkdir -p busco_summaries
echo "making summary busco" | tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log

cp "$OUT"/04_busco/*/*/short_summary.specific.burkholderiales_odb10.*.txt busco_summaries/

conda deactivate