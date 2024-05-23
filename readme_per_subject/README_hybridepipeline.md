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

