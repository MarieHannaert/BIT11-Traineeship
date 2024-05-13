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
kraken2 -v | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda activate krona
conda list | grep krona | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda deactivate
fastp -v >> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda activate shovill
conda list | grep shovill | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda deactivate
conda activate skani 
conda list | grep skani | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda deactivate 
conda activate quast
conda list | grep quast | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda deactivate
conda activate busco
conda list | grep busco | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda deactivate
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#adding the command to the log file
echo "the command that was used is:"| tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "complete_illuminapipeline.sh" $1 $2 $3 $4 |tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "This was performed in the following directory: $START_DIR" |tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log

echo "The analysis started at" $(date '+%Y/%m/%d_%H:%M') | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#checking which file format
#if bz then reformat to gz 
#if gz then continue
#if something else then exit, because needs to be gz of bz2
echo "checking fileformat and reformat if needed at" $(date '+%H:%M') | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
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
echo "File reformatting done and starting fastqc at" $(date '+%H:%M') | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#performing fastqc on the gz samples 
echo Performing fastqc | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
mkdir -p "$OUT"/00_fastqc
fastqc -t 32 *.gz --extract -o "$OUT"/00_fastqc 
#activating the mamba env 
#conda init 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "fastqc done, starting multiqc at" $(date '+%H:%M') | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda activate multiqc 
#perfomring the multiqc on the fastqc samples
cd $OUT
echo performing multiqc | tee -a "$DATE_TIME"_Illuminapipeline.log
multiqc 00_fastqc 2>> "$DATE_TIME"_Illuminapipeline.log
echo removing 00_fastqc/ | tee -a "$DATE_TIME"_Illuminapipeline.log
rm -rd 00_fastqc/ 2>> "$DATE_TIME"_Illuminapipeline.log
#deactivating the mamba env
conda deactivate
#renaming the multiqc directory 
mv multiqc_data/ 01_multiqc
mv multiqc_report.html 01_multiqc/ 

#going back up to the samples
cd ..

echo "multiqc done, starting Kraken and krona at" $(date '+%H:%M') | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#kraken2 and krona part
conda activate krona
mkdir -p "$OUT"/02_Kraken_krona
touch "$OUT"/02_Kraken_krona/"$DATE_TIME"_kraken.log
touch "$OUT"/02_Kraken_krona/"$DATE_TIME"_krona.log
#Kraken2
for sample in `ls *.fq.gz | awk 'BEGIN{FS=".fq.*"}{print $1}'`
do
    #running Kraken2 on each sample
    echo "Running Kraken2 on $sample" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    kraken2 --gzip-compressed "$sample".fq.gz --db /home/genomics/bioinf_databases/kraken2/Standard --report "$OUT"/02_Kraken_krona/"$sample"_kraken2.report --threads $4 --quick --memory-mapping 2>> "$OUT"/02_Kraken_krona/"$DATE_TIME"_kraken.log

    #running Krona on the report
    echo "Running Krona on $sample" |tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    ktImportTaxonomy -t 5 -m 3 -o "$OUT"/02_Kraken_krona/"$sample"_krona.html "$OUT"/02_Kraken_krona/"$sample"_kraken2.report 2>> "$OUT"/02_Kraken_krona/"$DATE_TIME"_krona.log

    #removing the kraken reports after using these for krona
    echo "Removing kraken2 report" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    rm "$OUT"/02_Kraken_krona/"$sample"_kraken2.report 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log

done

echo "Finished running Kraken2 and Krona and starting fastp at" $(date '+%H:%M')  | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda deactivate

#now perfroming fastp on the samples
#making a folder for the trimmed samples
mkdir -p "$OUT"/03_fastp
touch "$OUT"/03_fastp/"$DATE_TIME"_fastp.log
#loop over read files
echo "performing trimming with fastp" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
for g in `ls *_1.fq.gz | awk 'BEGIN{FS="_1.fq.gz"}{print $1}'`
do
    echo "Working on trimming genome $g with fastp" 
    fastp -w 32 -i "$g"_1.fq.gz -I "$g"_2.fq.gz -o "$OUT"/03_fastp/"$g"_1.fq.gz -O "$OUT"/03_fastp/"$g"_2.fq.gz -h "$OUT"/03_fastp/"$g"_fastp.html -j "$OUT"/03_fastp/"$g"_fastp.json --detect_adapter_for_pe 2>> "$OUT"/03_fastp/"$DATE_TIME"_fastp.log
done
echo "Finished trimming with fastp and starting shovill at" $(date '+%H:%M') | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log


#Shovill part
conda activate shovill
#making a folder for the output 
mkdir -p "$OUT"/04_shovill
#moving in to the file with the needed samples
cd "$OUT"/03_fastp/

FILES=(*_1.fq.gz)
#loop over all files in $FILES and do the assembly for each of the files
for f in "${FILES[@]}" 
do 
	SAMPLE=`basename $f _1.fq.gz`  	#extract the basename from the file and store it in the variable SAMPLE

	#run Shovill
	shovill --R1 "$SAMPLE"_1.fq.gz --R2 "$SAMPLE"_2.fq.gz --cpus 16 --ram 16 --minlen 500 --trim -outdir ../04_shovill/"$SAMPLE"/ 
	echo Assembly "$SAMPLE" done ! 
done
echo "Assembly done!" | tee -a ../"$DATE_TIME"_Illuminapipeline.log
#moving back to the main directory
cd ..
conda deactivate

#selecting and moving needed files 
#moving to location top perform the following command
mkdir -p assemblies
cd 04_shovill/
#collecting all the contigs.fa files in assemblies folder
echo "collecting contig files in assemblies/" | tee -a ../"$DATE_TIME"_Illuminapipeline.log
for d in `ls -d *`; do cp "$d"/contigs.fa ../assemblies/"$d".fna; done

cd ..
#removing the data that is not needed anymore 
echo "removing fastp samples" | tee -a "$DATE_TIME"_Illuminapipeline.log
rm 03_fastp/*.fq.gz 
#rm 04_shovill/*/*{.fa,.gfa,.corrections,.fasta}

echo "Finished Shovill and starting skANI at" $(date '+%H:%M') | tee -a "$DATE_TIME"_Illuminapipeline.log


# performing skani
conda activate skani 
#making a directory and a log file 
mkdir 05_skani 
touch 05_skani/"$DATE_TIME"_skani.log
echo "performing skani" | tee -a "$DATE_TIME"_Illuminapipeline.log
#command to perform skani on the 
skani search assemblies/*.fna -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o 05_skani/skani_results_file.txt -t 24 -n 1 2>> skani/"$DATE_TIME"_skani.log
conda deactivate 

echo "Finished skANI and starting Quast at" $(date '+%H:%M') | tee -a "$DATE_TIME"_Illuminapipeline.log

#quast part 
conda activate quast

echo "performing quast" | tee -a "$DATE_TIME"_Illuminapipeline.log
for f in assemblies/*.fna; do quast.py $f -o 06_quast/$f;done 

# Create a file to store the QUAST summary table
echo "making a summary of quast data" | tee -a "$DATE_TIME"_Illuminapipeline.log
touch 06_quast/quast_summary_table.txt

# Add the header to the summary table
echo -e "Assembly\tcontigs (>= 0 bp)\tcontigs (>= 1000 bp)\tcontigs (>= 5000 bp)\tcontigs (>= 10000 bp)\tcontigs (>= 25000 bp)\tcontigs (>= 50000 bp)\tTotal length (>= 0 bp)\tTotal length (>= 1000 bp)\tTotal length (>= 5000 bp)\tTotal length (>= 10000 bp)\tTotal length (>= 25000 bp)\tTotal length (>= 50000 bp)\tcontigs\tLargest contig\tTotal length\tGC (%)\tN50\tN90\tauN\tL50\tL90\tN's per 100 kbp" >> 06_quast/quast_summary_table.txt

# Initialize a counter
counter=1

# Loop over all the transposed_report.tsv files and read them
for file in $(find -type f -name "transposed_report.tsv"); do
    # Show progress
    echo "Processing file: $counter"

    # Add the content of each file to the summary table (excluding the header)
    tail -n +2 $file >> 06_quast/quast_summary_table.txt

    # Increment the counter
    counter=$((counter+1))
done

conda deactivate

#part were I make a xlsx file of the skANI output and the Quast output 
echo "making xlsx of skANI and quast" | tee -a "$DATE_TIME"_Illuminapipeline.log
skani_quast_to_xlsx.py "$DIR"/"$OUT"/ 2>> "$DATE_TIME"_Illuminapipeline.log

#part for beeswarm visualisation of assemblies 
echo "making beeswarm visualisation of assemblies" | tee -a "$DATE_TIME"_Illuminapipeline.log
beeswarm_vis_assemblies.R "$DIR/$OUT/quast/quast_summary_table.txt" 2>> "$DATE_TIME"_Illuminapipeline.log

echo "Finished Quast and starting Busco at" $(date '+%H:%M') | tee -a "$DATE_TIME"_Illuminapipeline.log

#Busco part
conda activate busco

echo "performing busco" | tee -a "$DATE_TIME"_Illuminapipeline.log
for sample in `ls assemblies/*.fna | awk 'BEGIN{FS=".fna"}{print $1}'`; do busco -i "$sample".fna -o 07_busco/"$sample" -m genome --auto-lineage-prok -c 32 ; done

#extra busco part
#PLOT SUMMARY of busco
mkdir busco_summaries
echo "making summary busco" | tee -a "$DATE_TIME"_Illuminapipeline.log

cp 07_busco/*/*/short_summary.specific.burkholderiales_odb10.*.txt busco_summaries/
cd busco_summaries/ 
#to generate a summary plot in PNG
generate_plot.py -wd .
#going back to main directory
cd ..

conda deactivate

#End of primary analysis
echo "end of primary analysis for Illumina or short reads at" $(date '+%Y/%m/%d_%H:%M') | tee -a "$DATE_TIME"_Illuminapipeline.log


