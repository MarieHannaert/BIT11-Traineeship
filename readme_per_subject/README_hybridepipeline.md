# script hybride pipeline 
In this script will be made a pipeline for hybride reads, so loan-reads and short-reads. 
## Information of supervisor
I need to make an input csv with the long ans hort reads. 
The files will look as followed: 
>voor de hybride sample_{1,2}.fq.bz2 en sample_long.fq.bz2, die gebruik je om de csv te maken voor inupt

after this is just hybracter who does most of the job, then quality control with skANI, quast and busco

I will base me on my previous scripts to make this pipeline. 

## CSV part
First I will look up how the input for hybracter needs to be, so that I have a clear sight on 
> **Input csv**
hybracter hybrid and hybracter long require an input csv file to be specified with --input. No other inputs are required.
This file requires no headers.
Other than the reads, hybracter requires a value for a lower bound the minimum chromosome length for each isolate in base pairs. It must be an integer.
hybracter will denote contigs about this value as chromosome(s) and if it can recover a chromosome, it will denote the isolate as complete.
In practice, I suggest choosing 90% of the estimated chromosome size for this value.
e.g. for S. aureus, I'd choose 2500000, E. coli, 4000000, P. aeruginosa 5500000.
hybracter hybrid
hybracter hybrid requires an input csv file with 5 columns.
Each row is a sample.
- Column 1 is the sample name you want for this isolate.
- Column 2 is the long read fastq file.
- Column 3 is the minimum chromosome length for that sample.
- Column 4 is the R1 short read fastq file
- Column 5 is the R2 short read fastq file.
e.g.
````
s_aureus_sample1,sample1_long_read.fastq.gz,2500000,sample1_SR_R1.fastq.gz,sample1_SR_R2.fastq.gz
p_aeruginosa_sample2,sample2_long_read.fastq.gz,5500000,sample2_SR_R1.fastq.gz,sample2_SR_R2.fastq.gz
````

This is what I made:
````
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
````
The third column is still empty because I don't know what to fill in for max chromosome lengt. 
I asked my supervisor this and he said this isn't needed, but now I don't know if I need to leave it empty or set something in place. 

## Test CVS 
SO I runned this part, but there is a small error. I tested it with two sets, but I got 6 lines in the csv. This isn't correct, the problem is that I selected on "*.fq.gz" but he also takes _1 and _2 
so I will select on "*_1.fq.gz" I think that will sove the problem. 

This isn't correct either, this is my output:
````
GBBC_502_1.fq.gz_hybrid,GBBC_502_1.fq.gz.fq.gz, ,GBBC_502_1.fq.gz_1.fq.gz,GBBC_502_1.fq.gz_2.fq.gz
````
There is a double fq.gz part. 

I changed it to 

````
for file in *_1.fq.gz; do
  sample=${file%_1.fq.gz}
  echo "${sample}_hybrid,${sample}.fq.gz,${sample}_1.fq.gz,${sample}_2.fq.gz" >> "$OUT"/input_table_hybracter.csv
done
````
now I got as output: 
````
GBBC_502_hybrid,GBBC_502.fq.gz,GBBC_502_1.fq.gz,GBBC_502_2.fq.gz
````
This is correct. 

I added "cd "$START_DIR"" because then I think the directories will be more correct 

## Adding hybracter part 
now that the CSV is correct I can start by adding the hybracter part. 
The command that must be included in my script is the following:
````
hybracter hybrid -i <input.csv> -o <output_dir> -t <threads> 
````
This is from the hybracter documentation. 

I added the following block of code: 
````
#Hybracter
echo "Performing Hybracter"| tee -a "$OUT"/"$DATE_TIME"_Hybridepipeline.log
mkdir -p 01_hybracter
hybracter hybrid -i "$OUT"/input_table_hybracter.csv -o "$OUT"/01_hybracter/ -t "$4" 2>> "$OUT"/01_hybracter/"$DATE_TIME"_hybracter.log
````
I will test this, There were small errors: 
I forgot the output before the output directory. And I forgot that hybracter a conda env was. 
so I fixed these things, and test this again: 
The hybracter didn't work, output logfile: 
````

hybracter version 0.6.0

[2024:05:24 11:12:57] Copying system default config to testing_csv/01_hybracter/config.yaml
[2024:05:24 11:12:57] Updating config file with new values
[2024:05:24 11:12:57] Writing config file to testing_csv/01_hybracter/config.yaml
[2024:05:24 11:12:57] ------------------
[2024:05:24 11:12:57] | Runtime config |
[2024:05:24 11:12:57] ------------------

args:
  contaminants: none
  databases: null
  dnaapler_custom_db: none
  flyeModel: --nano-hq
  input: testing_csv/input_table_hybracter.csv
  log: testing_csv/01_hybracter/hybracter.log
  logic: best
  medakaModel: r1041_e82_400bps_sup_v4.2.0
  min_length: 1000
  min_quality: 9
  no_medaka: false
  no_pypolca: false
  output: testing_csv/01_hybracter/
  single: false
  skip_qc: false
  subsample_depth: 100
qc:
  compression: 5
  hostRemoveFlagstat: -f 4 -F 3584
  minimapIndex: -I 8G
  minimapModel: map-ont
resources:
  big:
    cpu: 16
    mem: 32000
    time: '23:59:00'
  med:
    cpu: 8
    mem: 16000
    time: 08:00:00
  sml:
    cpu: 1
    mem: 4000
    time: 00:00:05

[2024:05:24 11:12:57] ---------------------
[2024:05:24 11:12:57] | Snakemake command |
[2024:05:24 11:12:57] ---------------------

snakemake -s /opt/miniforge3/envs/hybracterENV/lib/python3.12/site-packages/hybracter/workflow/hybrid.smk --configfile testing_csv/01_hybracter/config.yaml --jobs 4 --use-conda --conda-prefix /opt/miniforge3/envs/hybracterENV/lib/python3.12/site-packages/hybracter/workflow/conda --rerun-incomplete --printshellcmds --nolock --show-failed-logs --conda-frontend mamba
Config file /opt/miniforge3/envs/hybracterENV/lib/python3.12/site-packages/hybracter/workflow/../config/config.yaml is extended by additional config specified via the command line.

    FATAL: Error parsing testing_csv/input_table_hybracter.csv. Line ['GBBC_502_hybrid', 'GBBC_502.fq.gz', 'GBBC_502_1.fq.gz', 'GBBC_502_2.fq.gz'] 
    does not have 5 columns. 
    Please check the formatting of testing_csv/input_table_hybracter.csv. 
[2024:05:24 11:12:58] ERROR: Snakemake failed
````
So it's because my CSV file only has 4 columns. 
And he expect 5 columns. 

So I changed my csv with an open space in column 3, but this wasn't the solution. 
    FATAL: Error parsing testing_csv/input_table_hybracter.csv. One of 
    GBBC_502.fq.gz or 
    GBBC_502_1.fq.gz or 
    GBBC_502_2.fq.gz 
    does not exist or    is not an integer. 
    Check formatting, and that 
    file names and file paths are correct.

## Asking after chromosome size
The solution we have, is we going to ask after the 90% of the estimated chromosome size. and then fill it in in the CSV 

This didn't directly work, because READ gives a string and not an intiger, and for the csv it must be an intiger

The errors wasn't about the intigre, it was about one sample that missed an "_" so wasn't recoginised. 

NOw I'm running it again and, 
Now it wokred, it runned for a long time. 

I got a lot of different outputs. 
I thinks that the most important one is in the **/home/genomics/mhannaert/data/mini_hybride/testing_csv/01_hybracter/FINAL_OUTPUT/incomplete/GBBC_504_hybrid_final.fasta** Because I think I will do further steps like skANI, Quast, Busco on these files. 

## Next steps
So the next steps will be adding the control tools. 

For these steps my supervisor told me to check for complete and inclomplete because both can happen.
## Adding skANI
 

For skANI I used my existing code: 
````

````

## Adding Quast 
## Adding Busco