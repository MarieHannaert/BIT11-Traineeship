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
For racon I went back looking at the howto file from my supervisor, here he says you first have to run minimap2 on the samples. 

the info that is important from the howto file: 
````
#first map genome with minimap2	
minimap2 -t [threads] -x map-ont -secondary=no -m 100 $genome $reads | gzip - > aln.paf.gz

# then run racon
racon -u -t [threads] $reads aln.paf.gz $genome > ${base}_racon.fasta
````
I only don't exacly now what must be filled in in the variables "$". I send a message to my supervisor and now it's clear, the reads are like I tought from porechop, and the genome is the result from the assembler, in this case thus flye. 

So I need both fasta files from porchop and from flye as input. 
with this information I made the following part: 
first I made the part for minimap2:
````
conda activate minimap2
for sample in `ls *_OUTPUT.fasta | awk 'BEGIN{FS="_OUTPUT.fasta"}{print $1}'`;
do minimap2 -t "$4" -x map-ont -secondary=no -m 100 ../04_flye/flye_out_"$sample"/assembly.fasta "$sample"_OUTPUT.fasta | gzip - > ../05_racon/"$sample"_aln.paf.gz;
done
conda deactivate 
````
I tested this part in the command line: 
````
for sample in `ls *_OUTPUT.fasta | awk 'BEGIN{FS="_OUTPUT.fasta"}{print $1}'`;
do minimap2 -t 4 -x map-ont -secondary=no -m 100 ../04_flye/flye_out_"$sample"/assembly.fasta "$sample"_OUTPUT.fasta | gzip - > ../05_racon/"$sample"_aln.paf.gz;
````
This worked


for the racon p art I made the following: 
````
for sample in `ls *_OUTPUT.fasta | awk 'BEGIN{FS="_OUTPUT.fasta"}{print $1}'`;
do racon -u -t "$4" "$sample"_OUTPUT.fasta ../05_racon/"$sample"_aln.paf.gz ../04_flye/flye_out_"$sample"/assembly.fasta > "$sample"_racon.fasta;
done
````
I again tested this in the command line: 
````
for sample in `ls *_OUTPUT.fasta | awk 'BEGIN{FS="_OUTPUT.fasta"}{print $1}'`;
do racon -u -t 4 "$sample"_OUTPUT.fasta ../05_racon/"$sample"_aln.paf.gz ../04_flye/flye_out_"$sample"/assembly.fasta > ../05_racon/"$sample"_racon.fasta;
done
````
This also worked.

## SkANI
for this part and the following parts, I will use my code from the previous script, The only thing is that there I made assemblies folder with all the assemblies in. The samples were I need to run skani on is the result of the consensus that was made by Racon. 

I want looking on the skani documentation, and there stood that skani could be runnend on fasta files. so I don't need to change anything. Just define the wright input.

````
#skANI
conda activate skani 
#making a directory and a log file 
mkdir -p 06_skani 
touch 06_skani/"$DATE_TIME"_skani.log
echo "performing skani" | tee -a "$OUT"/"$DATE_TIME"_Longreadpipeline.log
#command to perform skani on the 
skani search 05_racon/*_racon.fasta -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o 06_skani/skani_results_file.txt -t 24 -n 1 2>> 06_skani/"$DATE_TIME"_skani.log
conda deactivate 

echo "Finished skANI and starting Quast at $(date '+%H:%M')" | tee -a "$DATE_TIME"_Illuminapipeline.log
````
I again runned it in the command line 
````
skani search 05_racon/*_racon.fasta -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o 06_skani/skani_results_file.txt -t 24 -n 1
````
It worked in the command line
## Quast
````
#quast
conda activate quast
cd 05_racon/
echo "performing quast" | tee -a "$DATE_TIME"_Longreadpipeline.log
for f in *_racon.fasta; do quast.py "$f" -o ../07_quast/"$f";done 
cd ..
#quast summary
# Create a file to store the QUAST summary table
echo "making a summary of quast data" | tee -a "$DATE_TIME"_Longreadpipeline.log
touch 07_quast/quast_summary_table.txt

# Add the header to the summary table
echo -e "Assembly\tcontigs (>= 0 bp)\tcontigs (>= 1000 bp)\tcontigs (>= 5000 bp)\tcontigs (>= 10000 bp)\tcontigs (>= 25000 bp)\tcontigs (>= 50000 bp)\tTotal length (>= 0 bp)\tTotal length (>= 1000 bp)\tTotal length (>= 5000 bp)\tTotal length (>= 10000 bp)\tTotal length (>= 25000 bp)\tTotal length (>= 50000 bp)\tcontigs\tLargest contig\tTotal length\tGC (%)\tN50\tN90\tauN\tL50\tL90\tN's per 100 kbp" >> 07_quast/quast_summary_table.txt

# Initialize a counter
counter=1

# Loop over all the transposed_report.tsv files and read them
for file in $(find -type f -name "transposed_report.tsv"); do
    # Show progress
    echo "Processing file: $counter"

    # Add the content of each file to the summary table (excluding the header)
    tail -n +2 "$file" >> 07_quast/quast_summary_table.txt

    # Increment the counter
    counter=$((counter+1))
done

conda deactivate
````
I perfromed this also in the command line: 
````
for f in *_racon.fasta; do quast.py "$f" -o ../07_quast/"$f";done
````
I did also the following steps for the summary table and everything worked. 
## Xlsx & Beeswarmvisualisation
I added this 
````
#xlsx
#part were I make a xlsx file of the skANI output and the Quast output 
echo "making xlsx of skANI and quast" | tee -a "$DATE_TIME"_Longreadpipeline.log
skani_quast_to_xlsx.py "$DIR"/"$OUT"/ 2>> "$DATE_TIME"_Longreadpipeline.log

#beeswarmvisualisation
#part for beeswarm visualisation of assemblies 
echo "making beeswarm visualisation of assemblies" | tee -a "$DATE_TIME"_Longreadpipeline.log
beeswarm_vis_assemblies.R "$DIR/$OUT/07_quast/quast_summary_table.txt" 2>> "$DATE_TIME"_Longreadpipeline.log

mv skANI_Quast_output.xlsx 06_skani/
mv beeswarm_vis_assemblies.png 07_quast/
````
## Big first test of the whole script
