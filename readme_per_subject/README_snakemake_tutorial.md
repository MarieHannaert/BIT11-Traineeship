# Snakemake tutorial 
information I got from my supervisor: 

official documentation: 
https://snakemake.readthedocs.io/en/stable/ 

https://hackmd.io/@ctb/H1MUty3ZU

https://www.youtube.com/watch?v=r9PWnEmz_tc
This is a youtube video that apperently explaines it very well. 

https://www.schlosslab.org/just-enough-python/
This is the documentation for snakemake in R. 

https://carpentries-incubator.github.io/snakemake-novice-bioinformatics/ other snakemake documentation including the installation

http://ivory.idyll.org/blog/2023-snakemake-slithering-section-1.html
An other guide to learn snakemake 

## Before
In the official documentation there was a link to slides: https://slides.com/johanneskoester/snakemake-tutorial

So I first looked at these slides before doining anything. 
things I learned from the slides: 
- Define workflows in terms of rules
- you can use external scripts: python, R, jupyter notebooks
- Dependencies are determined top-down
- parallelization 
- defining resources 
- scheduling
- Scalable to any platform
- config files
- input functions 
- logging
- Cluster/cloud execution 
- configuration profiles
- Reproducible software installation
- Package management with conda 
- Containerization
- Using and combining workflows

## The installation
The commands I used to install snakemake in my own WSL. Because I worked@home (06/05/2024, afternoon) I needed to install it in my own WSL, because I don't have access to the sever of ILVO. For following the tutorial this was possible. 
````
curl -L https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh -o Mambaforge-Linux-x86_64.sh

bash Mambaforge-Linux-x86_64.sh
````
The installation was succesful, was only the installation of mamba, now I will install snakemake 

first following preparing steps: 
````
mkdir snakemake-tutorial
cd snakemake-tutorial
````
No we will download some example data, for executing the example workflow of the tutorial: 
````
#downloading the data 
curl -L https://api.github.com/repos/snakemake/snakemake-tutorial-data/tarball -o snakemake-tutorial-data.tar.gz

#extracting the data
tar --wildcards -xf snakemake-tutorial-data.tar.gz --strip 1 "*/data" "*/environment.yaml"
````

Now, installing the conda env for snakemake
````
conda activate base

conda install -n base -c conda-forge mamba

mamba env create --name snakemake-tutorial --file environment.yaml
````
Now activating the env: 
````
conda activate snakemake-tutorial
````
No I'm ready for following the tutorial
## Following the tutorial from the documentation
https://snakemake.readthedocs.io/en/stable/tutorial/tutorial.html#tutorial 

when I take a look in the folder that was made I saw the following: 
````
#in the folder of snakemake-tutorial
data  environment.yaml  snakemake-tutorial-data.tar.gz 
#in the data folder 
genome.fa  genome.fa.amb  genome.fa.ann  genome.fa.bwt  genome.fa.fai  genome.fa.pac  genome.fa.sa  samples
````
### Basics: an example workflow
https://snakemake.readthedocs.io/en/stable/tutorial/basics.html

>A Snakemake workflow is defined by specifying rules in a Snakefile. Rules decompose the workflow into small steps (for example, the application of a single tool) by specifying how to create sets of output files from sets of input files. Snakemake automatically determines the dependencies between the rules by matching file names.

>In the following, we will introduce the Snakemake syntax by creating an example workflow. The workflow comes from the domain of genome analysis. It maps sequencing reads to a reference genome and calls variants on the mapped reads. The tutorial does not require you to know what this is about. Nevertheless, we provide some background in the following paragraph. Background:The genome of a living organism encodes its hereditary information. It serves as a blueprint for proteins, which form living cells, carry information and drive chemical reactions. Differences between species, populations or individuals can be reflected by differences in the genome. Certain variants can cause syndromes or predisposition for certain diseases, or cause cancerous growth in the case of tumour cells that have accumulated changes with respect to healthy cells. This makes the genome a major target of biological and medical research. Today, it is often analyzed with DNA sequencing, producing gigabytes of data from a single biological sample (for example a biopsy of some tissue). For technical reasons, DNA sequencing cuts the DNA of a sample into millions of small pieces, called reads. In order to recover the genome of the sample, one has to map these reads against a known reference genome (for example, the human one obtained during the famous human genome project). This task is called read mapping. Often, it is of interest where an individual genome is different from the species-wide consensus represented with the reference genome. Such differences are called variants. They are responsible for harmless individual differences (like eye color), but can also cause diseases like cancer. By investigating the differences between the mapped reads and the reference sequence at a particular genome position, variants can be detected. This is a statistical challenge, because they have to be distinguished from artifacts generated by the sequencing process.
#### Step 1: Mapping reads
first I made a snakefile in the snakemake-tutorial folder 
In this snakefile I needed to add the following part, this is defining a rule: 
````
rule bwa_map:
    input:
        "data/genome.fa",
        "data/samples/A.fastq"
    output:
        "mapped_reads/A.bam"
    shell:
        "bwa mem {input} | samtools view -Sb - > {output}"
````
>A common error is to forget the comma between the input or output items. Since Python concatenates subsequent strings, this can lead to unexpected behavior.
I perfomed the following command: 
````
snakemake -np mapped_reads/A.bam
````
First I got the following output: 
````
Building DAG of jobs...
MissingRuleException:
No rule to produce mapped_reads/A.bam (if you use input functions make sure that they don't raise unexpected exceptions).
````
The problem was that I didn't saved the file with the snakemake command, so after I saved it and reperformed the command I got the following output: 
````
Building DAG of jobs...
Job stats:
job        count
-------  -------
bwa_map        1
total          1

Execute 1 jobs...

[Mon May  6 16:50:22 2024]
rule bwa_map:
    input: data/genome.fa, data/samples/A.fastq
    output: mapped_reads/A.bam
    jobid: 0
    reason: Missing output files: mapped_reads/A.bam
    resources: tmpdir=<TBD>

bwa mem data/genome.fa data/samples/A.fastq | samtools view -Sb - > mapped_reads/A.bam
Job stats:
job        count
-------  -------
bwa_map        1
total          1

Reasons:
    (check individual jobs above for details)
    output files have to be generated:
        bwa_map

This was a dry-run (flag -n). The order of jobs does not reflect the order of execution.
````
you can execute the workflow with the following command: 
````
snakemake --cores 1 mapped_reads/A.bam
````
the result is them the following: 
````
Assuming unrestricted shared filesystem usage.
Building DAG of jobs...
Using shell: /usr/bin/bash
Provided cores: 1 (use --cores to define parallelism)
Rules claiming more threads will be scaled down.
Job stats:
job        count
-------  -------
bwa_map        1
total          1

Select jobs to execute...
Execute 1 jobs...

[Mon May  6 16:57:59 2024]
localrule bwa_map:
    input: data/genome.fa, data/samples/A.fastq
    output: mapped_reads/A.bam
    jobid: 0
    reason: Missing output files: mapped_reads/A.bam
    resources: tmpdir=/tmp

[M::bwa_idx_load_from_disk] read 0 ALT contigs
[M::process] read 25000 sequences (2525000 bp)...
[M::mem_process_seqs] Processed 25000 reads in 1.974 CPU sec, 1.978 real sec
[main] Version: 0.7.17-r1188
[main] CMD: bwa mem data/genome.fa data/samples/A.fastq
[main] Real time: 2.552 sec; CPU: 2.066 sec
[Mon May  6 16:58:01 2024]
Finished job 0.
1 of 1 steps (100%) done
Complete log: .snakemake/log/2024-05-06T165758.918667.snakemake.log
````
#### Step 2: Generalizing the read mapping rule
-> Snakemake allows generalizing rules by using named wildcards
we're going to replace the A from the first part with this {sample}

updating the file modification date of the input file via: 
````
touch data/samples/A.fastq
````
rerun by the following command: 
````
snakemake -np mapped_reads/A.bam mapped_reads/B.bam
````
the output: 
````
Building DAG of jobs...
Job stats:
job        count
-------  -------
bwa_map        2
total          2

Execute 2 jobs...

[Mon May  6 17:21:48 2024]
rule bwa_map:
    input: data/genome.fa, data/samples/A.fastq
    output: mapped_reads/A.bam
    jobid: 1
    reason: Updated input files: data/samples/A.fastq
    wildcards: sample=A
    resources: tmpdir=<TBD>

bwa mem data/genome.fa data/samples/A.fastq | samtools view -Sb - > mapped_reads/A.bam

[Mon May  6 17:21:48 2024]
rule bwa_map:
    input: data/genome.fa, data/samples/B.fastq
    output: mapped_reads/B.bam
    jobid: 0
    reason: Missing output files: mapped_reads/B.bam
    wildcards: sample=B
    resources: tmpdir=<TBD>

bwa mem data/genome.fa data/samples/B.fastq | samtools view -Sb - > mapped_reads/B.bam
Job stats:
job        count
-------  -------
bwa_map        2
total          2

Reasons:
    (check individual jobs above for details)
    output files have to be generated:
        bwa_map
    updated input files:
        bwa_map

This was a dry-run (flag -n). The order of jobs does not reflect the order of execution.
````
#### Step 3: Sorting read alignments
To read alignments in the BAM files to be sorted, via the sam tools, I need to add the following: 
````
rule samtools_sort:
    input:
        "mapped_reads/{sample}.bam"
    output:
        "sorted_reads/{sample}.bam"
    shell:
        "samtools sort -T sorted_reads/{wildcards.sample} "
        "-O bam {input} > {output}"
````
to execute the update snakemake file: 
````
snakemake -np sorted_reads/B.bam
````
the following output is the part for the samtools that I added: 
````
rule samtools_sort:
    input: mapped_reads/B.bam
    output: sorted_reads/B.bam
    jobid: 0
    reason: Missing output files: sorted_reads/B.bam; Input files updated by another job: mapped_reads/B.bam
    wildcards: sample=B
    resources: tmpdir=<TBD>

samtools sort -T sorted_reads/B -O bam mapped_reads/B.bam > sorted_reads/B.bam
Job stats:
job              count
-------------  -------
bwa_map              1
samtools_sort        1
total                2

Reasons:
    (check individual jobs above for details)
    input files updated by another job:
        samtools_sort
    output files have to be generated:
        bwa_map, samtools_sort

This was a dry-run (flag -n). The order of jobs does not reflect the order of execution.
````
#### Step 4: Indexing read alignments and visualizing the DAG of jobs
now I needed to add the part for the indexing via the samtools: 
````
rule samtools_index:
    input:
        "sorted_reads/{sample}.bam"
    output:
        "sorted_reads/{sample}.bam.bai"
    shell:
        "samtools index {input}"
````
By executing the following command, this must result in a directed acyclic graph (DAG): 
````
snakemake --dag sorted_reads/{A,B}.bam.bai | dot -Tsvg > dag.svg
````
The result is dag.svg file 
