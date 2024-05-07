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
#### Step 5: Calling genomic variants
Today I'm again at ILVO self, so for further I will perform the next steps op the ILVO server. I have also placed everything in the wright folder: **/home/genomics/mhannaert/Tutorial_snakemake**
The Snakefile can be found on the following location: **/home/genomics/mhannaert/Tutorial_snakemake/Snakefile**

For aggregate the mapped reads from all samples and jointly call genomic variants on them. For the variant calling, we will combine the two utilities samtools and bcftools. Snakemake provides a helper function for collecting input files that helps us to describe the aggregation in this step, this is added to the Snakefile by the following part: 
````
rule bcftools_call:
    input:
        fa="data/genome.fa",
        bam=expand("sorted_reads/{sample}.bam", sample=SAMPLES),
        bai=expand("sorted_reads/{sample}.bam.bai", sample=SAMPLES)
    output:
        "calls/all.vcf"
    shell:
        "bcftools mpileup -f {input.fa} {input.bam} | "
        "bcftools call -mv - > {output}"
````
>For long shell commands like this one, it is advisable to split the string over multiple indented lines. Python will automatically merge it into one. Further, you will notice that the input or output file lists can contain arbitrary Python statements, as long as it returns a string, or a list of strings. 

#### Step 6: Using custom scripts
to generate a histogram of the quality scores that have been assigned to the variant calls in the file calls/all.vcf, I needed to add to following part to my snakefile: 
````
rule plot_quals:
    input:
        "calls/all.vcf"
    output:
        "plots/quals.svg"
    script:
        "scripts/plot-quals.py"
````
I needed to make to following script in the following **/home/genomics/mhannaert/Tutorial_snakemake/scripts/plot-quals.py**: 
````
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pysam import VariantFile

quals = [record.qual for record in VariantFile(snakemake.input[0])]
plt.hist(quals)

plt.savefig(snakemake.output[0])
````
#### Step 7: Adding a target rule
Adding the following part to the Snakefile:
````
rule all:
    input:
        "plots/quals.svg"
````
The whole pipeline can be executed by the following command:
````
snakemake -n
````
### Advanced: Decorating the example workflow
#### Step 1: Specifying the number of used threads
>For some tools, it is advisable to use more than one thread in order to speed up the computation. Snakemake can be made aware of the threads a rule needs with the threads directive
Specifying the number of treads can be done by the following part of code, this will replace the existing part of code for the bwa map part:
````
rule bwa_map:
    input:
        "data/genome.fa",
        "data/samples/{sample}.fastq"
    output:
        "mapped_reads/{sample}.bam"
    threads: 8
    shell:
        "bwa mem -t {threads} {input} | samtools view -Sb - > {output}"
````
#### Step 2: Config files
>  your workflow to be customizable, so that it can easily be adapted to new data. For this purpose, Snakemake provides a config file mechanism. Config files can be written in JSON or YAML, and are used with the configfile directive.

defining the config file in the example workflow is done by adding to the top of the Snakefile: 
````
configfile: "config.yaml"
````
Now with this previous part made, I needed to change the BCFtools part in the snakemfile with the following: 
````
rule bcftools_call:
    input:
        fa="data/genome.fa",
        bam=expand("sorted_reads/{sample}.bam", sample=config["samples"]),
        bai=expand("sorted_reads/{sample}.bam.bai", sample=config["samples"])
    output:
        "calls/all.vcf"
    shell:
        "bcftools mpileup -f {input.fa} {input.bam} | "
        "bcftools call -mv - > {output}"
````
#### Step 3: Input functions
> important to know that Snakemake workflows are executed in three phases. In the initialization phase, the files defining the workflow are parsed and all rules are instantiated. In the DAG phase, the directed acyclic dependency graph of all jobs is built by filling wildcards and matching input files to output files. In the scheduling phase, the DAG of jobs is executed, with jobs started according to the available resources.

specifying a input funtion for bwa_map by replacing the previous part in of the bwa part in the snakefile: 
````
def get_bwa_map_input_fastqs(wildcards):
    return config["samples"][wildcards.sample]

rule bwa_map:
    input:
        "data/genome.fa",
        get_bwa_map_input_fastqs
    output:
        "mapped_reads/{sample}.bam"
    threads: 8
    shell:
        "bwa mem -t {threads} {input} | samtools view -Sb - > {output}"
````
#### Step 4: Rule parameters
 to define arbitrary parameters for rules with the params directive, this can be done in the example with the following part, this will replace again the bwa_map part: 
 ````
 rule bwa_map:
    input:
        "data/genome.fa",
        get_bwa_map_input_fastqs
    output:
        "mapped_reads/{sample}.bam"
    params:
        rg=r"@RG\tID:{sample}\tSM:{sample}"
    threads: 8
    shell:
        "bwa mem -R '{params.rg}' -t {threads} {input} | samtools view -Sb - > {output}"
 ````
#### Step 5: Logging
 When you perform multiple steps it is desirable to log all the steps then when something doesn't go right you can trace where it went wrong. In a snakemake multiple steps can be done parallel, so here it is even more advisable to log the process. 

 For the bwa_map part this can be done by replacing that part with the following: 
 ````
 rule bwa_map:
    input:
        "data/genome.fa",
        get_bwa_map_input_fastqs
    output:
        "mapped_reads/{sample}.bam"
    params:
        rg=r"@RG\tID:{sample}\tSM:{sample}"
    log:
        "logs/bwa_mem/{sample}.log"
    threads: 8
    shell:
        "(bwa mem -R '{params.rg}' -t {threads} {input} | "
        "samtools view -Sb - > {output}) 2> {log}"
 ````
 > tip: make a subfolder /logs to store all the logfiles that are created 

#### Step 6: Temporary and protected files
It is interesting to save some output files as temporary because then it can be used when performing the workflow, but they don't need to be saved after the workflow is done. Because then you will lose some really usefull disk space. 

This can be done by the following: 
````
rule bwa_map:
    input:
        "data/genome.fa",
        get_bwa_map_input_fastqs
    output:
        temp("mapped_reads/{sample}.bam")
    params:
        rg=r"@RG\tID:{sample}\tSM:{sample}"
    log:
        "logs/bwa_mem/{sample}.log"
    threads: 8
    shell:
        "(bwa mem -R '{params.rg}' -t {threads} {input} | "
        "samtools view -Sb - > {output}) 2> {log}"
````
An other interesting option that can be added is the protection of files against accidental deleting them and modifying them when not wanted. This can be done by the following part: 
```
rule samtools_sort:
    input:
        "mapped_reads/{sample}.bam"
    output:
        protected("sorted_reads/{sample}.bam")
    shell:
        "samtools sort -T sorted_reads/{wildcards.sample} "
        "-O bam {input} > {output}"
```

after this part the workflow and tutorial are completed
I will now execute the worklfow again by the following command: 
````
snakemake -n
````
## youtube: An introduction to Snakemake tutorial for beginners
This youtube video is recommanded by my supervisor so I will take a look at it. 
https://www.youtube.com/watch?v=r9PWnEmz_tc
>Snakemake is a powerful tool for keeping track of data dependencies and to automate data analysis pipelines. In this episode of Code Club, Pat Shares how to install snakemake, convert a driver script to a simple Snakemake file, troubleshoot problems, create rules, use parameters, and test snakemake files. The overall goal of this project is to highlight reproducible research practices using a number of tools. The specific output from this project will be a map-based visual that shows the level of drought across the globe.

complementing blogpost: 
https://riffomonas.org/code_club/2022-09-15-snakemake

### The video 
I downloaded his github page to start with so I could follow the tutorial: 
https://github.com/riffomonas/drought_index/tree/0db270b74ae3eb3f0d5acd19016543f5a8d9649b
I cloned this in to my **/home/genomics/mhannaert/Tutorial_snakemake**
now it can be found: **/home/genomics/mhannaert/Tutorial_snakemake/drought_index** 
So I can work in this directory while followin the tutorial

I am in **/home/genomics/mhannaert/Tutorial_snakemake/tutorial_drought_index**
I removed the snakefile, so I could recreated at the same time with the video to learn. 

#### The snakefile
**/home/genomics/mhannaert/Tutorial_snakemake/tutorial_drought_index/Snakefile**

I added the following: 
````
rule get_all_archive:
    input: 
        script = "code/get_ghcnd_data.bash"
    output: 
        "data/ghcnd_all.tar.gz"
    params: 
        "ghcnd_all.tar.gz"
    shell:
        """
        {input.script} {params.file}
        """
````
The following part that was added to the snakefile was for making sure that it's in the right fileformat: 
````
rule get_all_filenames:
    input:
        script = "code/get_ghcnd_all_files.bash",
        archive = "data/ghcbd_all.tar.gz"
    output:
        "data/ghcnd-all.txt"
    shell:
        """
        {input.script}
        """
````
the param was left out because there weren't any. 

we run this: 
````
snakemake -np get_all_filenames
````
I got an error 
````
all_filenames
Building DAG of jobs...
MissingInputException in rule get_all_filenames in file /home/genomics/mhannaert/Tutorial_snakemake/tutorial_drought_index/Snakefile, line 12:
Missing input files for rule get_all_filenames:
    output: data/ghcnd-all.txt
    affected files:
        data/ghcbd_all.tar.gz
````
there was a typo in the archive file, rurun: 
````
Building DAG of jobs...
Job stats:
job                  count
-----------------  -------
get_all_archive          1
get_all_filenames        1
total                    2

Execute 1 jobs...

[Tue May  7 13:40:03 2024]
localrule get_all_archive:
    input: code/get_ghcnd_data.bash
    output: data/ghcnd_all.tar.gz
    jobid: 1
    reason: Missing output files: data/ghcnd_all.tar.gz
    resources: tmpdir=<TBD>


        code/get_ghcnd_data.bash ghcnd_all.tar.gz
        
Execute 1 jobs...

[Tue May  7 13:40:03 2024]
localrule get_all_filenames:
    input: code/get_ghcnd_all_files.bash, data/ghcnd_all.tar.gz
    output: data/ghcnd-all_files.txt
    jobid: 0
    reason: Missing output files: data/ghcnd-all_files.txt; Input files updated by another job: data/ghcnd_all.tar.gz
    resources: tmpdir=<TBD>


        code/get_ghcnd_all_files.bash
        
Job stats:
job                  count
-----------------  -------
get_all_archive          1
get_all_filenames        1
total                    2

Reasons:
    (check individual jobs above for details)
    input files updated by another job:
        get_all_filenames
    missing output files:
        get_all_archive, get_all_filenames

This was a dry-run (flag -n). The order of jobs does not reflect the order of execution.
````
Fixing the typo solved the error. 

we added an other part to the snakefile: 
````
rule get_inventory: 
    input:
        script="code/get_ghcnd_data.bash"
    output: 
        "data/ghcnd-inventory.txt"
    params:
        file="ghcnd-inventory.txt"
    shell: 
        """
        {input.script}{params.file}
        """
````
and rund it, it gave the correct output, something like above

an other rule was added: 
````
rule get_station_data: 
    input: 
        script = "code/get_ghcnd_data.bash"
    output: 
        "data/ghcnd-stations.txt"
    params: 
        file="ghcnd-stations.txt"
    shell:
        """
        {input.script}{params.file}
        """
````
als this was checked by running it with the -np option, and it worked. 

#### The enviroment
In the tutorial he is installing a new env, this isn't possible because I can't install anything on the server without premission. I am in the snakemake env that already exist on the server, so I will first try to perform the tasks on the server, but if it doesn't work I need to change to wsl to perform this because there I can install what I want. 

What I just learned is that I can update the dependencies in the **/home/genomics/mhannaert/Tutorial_snakemake/tutorial_drought_index/environment.yml** to the versions that are available on the server, than the change that it will work on the server will be bigger. 

I checked the versions in the mamba snakemake env by executing the following command: 
````
mamba list 
````
The channels I need are 
- conda-forge 
- base 
- bioconda
- R
I only fount as channels: conda-forge and bioconda
The packages that I need to begin with are: 
- r-base
- r-tidyverse
- wget
- snakemake 
when I search these in the list this are the versions I found 
````
snakemake   8.2.3   hdfd78af_0  bioconda
The rest couldn't be found
````
because of the lach of R and Base I will probably need to executed this in my WSL because I can't install anything

But I already updated the environment.yml file for snakemake with changing the version from 7.14.0 to 8.2.3

I asked my supervisor about the enviroment in combination with the server 

the answer is that the snakemake will download the needed packages and channels in an hidden file in the background. That's the reason why it is advized to make a snakemake folder so that everything of these env will be downloaded on the same page and this always can be found. An other tip was to make specific folders in the directory like /envs /data /samples so that it always has the same structure and easily can be found. 

thus a structure like this: 
````
snakemake/
├─ envs/
├─ tool1/
|  ├─ .snakemake
│  ├─ data/
│  ├─ samples/
│  ├─ Snakefile
│  ├─ scripts
├─ tool2/
│  ├─ .snakemake
│  ├─ data/
│  ├─ samples/
│  ├─ Snakefile
│  ├─ scripts
````

#### running snakemake 

A first run can be done by executing the following command: 
````
snakemake --dry-run get_all_archive
````
The --dry-run will not actualy run the snakemake, but it will check if everything is added properly and is correct in the snakemake file, so more like checking

The result of running this command: 
````
Building DAG of jobs...
Job stats:
job                count
---------------  -------
get_all_archive        1
total                  1

Execute 1 jobs...

[Tue May  7 12:16:41 2024]
localrule get_all_archive:
    input: code/get_ghcnd_data.bash
    output: data/ghcnd_all.tar.gz
    jobid: 0
    reason: Missing output files: data/ghcnd_all.tar.gz
    resources: tmpdir=<TBD>

Job stats:
job                count
---------------  -------
get_all_archive        1
total                  1

Reasons:
    (check individual jobs above for details)
    missing output files:
        get_all_archive

This was a dry-run (flag -n). The order of jobs does not reflect the order of execution.
````
an oter option then --dry-run is -np this will also not run it. But Thus the running worked the missing dependencies aren't a problem yet. 

#### Creating and using a targets rule 

when you run 
````
snakemake -np #thus without the rule specified
````
then it just runs the very first rule, here only "get_all_archive"

we added this part in the snakefile: 

````
rule targets:
    input:
        "data/ghcnd_all.tar.gz"
        "data/ghcnd-all_files.txt"
        "data/ghcnd-inventory.txt"
        "data/ghcnd-stations.txt"
````
when we now just rerun the command from above "snakemake -np" 
then the output looks like this: 
````
Building DAG of jobs...
MissingInputException in rule targets in file /home/genomics/mhannaert/Tutorial_snakemake/tutorial_drought_index/Snakefile, line 1:
Missing input files for rule targets:
    affected files:
        data/ghcnd_all.tar.gzdata/ghcnd-all_files.txtdata/ghcnd-inventory.txtdata/ghcnd-stations.txt
````
This is because I forgot the put a comma after each target, I fixed this in the snakefile and rerund it, now the output looks like this: 
````
Building DAG of jobs...
Job stats:
job                  count
-----------------  -------
get_all_archive          1
get_all_filenames        1
get_inventory            1
get_station_data         1
targets                  1
total                    5

Execute 3 jobs...

[Tue May  7 14:03:15 2024]
localrule get_station_data:
    input: code/get_ghcnd_data.bash
    output: data/ghcnd-stations.txt
    jobid: 4
    reason: Missing output files: data/ghcnd-stations.txt
    resources: tmpdir=<TBD>


        code/get_ghcnd_data.bashghcnd-stations.txt
        

[Tue May  7 14:03:15 2024]
localrule get_all_archive:
    input: code/get_ghcnd_data.bash
    output: data/ghcnd_all.tar.gz
    jobid: 1
    reason: Missing output files: data/ghcnd_all.tar.gz
    resources: tmpdir=<TBD>


        code/get_ghcnd_data.bash ghcnd_all.tar.gz
        

[Tue May  7 14:03:15 2024]
localrule get_inventory:
    input: code/get_ghcnd_data.bash
    output: data/ghcnd-inventory.txt
    jobid: 3
    reason: Missing output files: data/ghcnd-inventory.txt
    resources: tmpdir=<TBD>


        code/get_ghcnd_data.bashghcnd-inventory.txt
        
Execute 1 jobs...

[Tue May  7 14:03:15 2024]
localrule get_all_filenames:
    input: code/get_ghcnd_all_files.bash, data/ghcnd_all.tar.gz
    output: data/ghcnd-all_files.txt
    jobid: 2
    reason: Missing output files: data/ghcnd-all_files.txt; Input files updated by another job: data/ghcnd_all.tar.gz
    resources: tmpdir=<TBD>


        code/get_ghcnd_all_files.bash
        
Execute 1 jobs...

[Tue May  7 14:03:15 2024]
localrule targets:
    input: data/ghcnd_all.tar.gz, data/ghcnd-all_files.txt, data/ghcnd-inventory.txt, data/ghcnd-stations.txt
    jobid: 0
    reason: Input files updated by another job: data/ghcnd-all_files.txt, data/ghcnd-stations.txt, data/ghcnd-inventory.txt, data/ghcnd_all.tar.gz
    resources: tmpdir=<TBD>

Job stats:
job                  count
-----------------  -------
get_all_archive          1
get_all_filenames        1
get_inventory            1
get_station_data         1
targets                  1
total                    5

Reasons:
    (check individual jobs above for details)
    input files updated by another job:
        get_all_filenames, targets
    missing output files:
        get_all_archive, get_all_filenames, get_inventory, get_station_data

This was a dry-run (flag -n). The order of jobs does not reflect the order of execution.
````
So till here, it is a succes. 

```
snakemake -c 1
```
the "-c 1" means use one core processer 
I run this command above. 
the output: 
````
Building DAG of jobs...
Retrieving input from storage.
Using shell: /usr/bin/bash
Provided cores: 1 (use --cores to define parallelism)
Rules claiming more threads will be scaled down.
Job stats:
job                  count
-----------------  -------
get_all_archive          1
get_all_filenames        1
get_inventory            1
get_station_data         1
targets                  1
total                    5

Select jobs to execute...
Execute 1 jobs...

[Tue May  7 14:07:34 2024]
localrule get_station_data:
    input: code/get_ghcnd_data.bash
    output: data/ghcnd-stations.txt
    jobid: 4
    reason: Missing output files: data/ghcnd-stations.txt
    resources: tmpdir=/tmp

/usr/bin/bash: line 2: code/get_ghcnd_data.bashghcnd-stations.txt: No such file or directory
[Tue May  7 14:07:34 2024]
Error in rule get_station_data:
    jobid: 4
    input: code/get_ghcnd_data.bash
    output: data/ghcnd-stations.txt
    shell:
        
        code/get_ghcnd_data.bashghcnd-stations.txt
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-07T140734.199970.snakemake.log
WorkflowError:
At least one job did not complete successfully.
````
I found the error, There was no space betwen "{input.script} {params.file}" so I added everywhere a space and rerund it, output was to mutch to show, but now it runned completly and worked thus. 

But it gave again an error: 
````
Waiting at most 5 seconds for missing files.
MissingOutputException in rule get_all_filenames in file /home/genomics/mhannaert/Tutorial_snakemake/tutorial_drought_index/Snakefile, line 19:
Job 2  completed successfully, but some output files are missing. Missing files after 5 seconds. This might be due to filesystem latency. If that is the case, consider to increase the wait time with --latency-wait:
data/ghcnd-all_files.txt
Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-07T141809.209127.snakemake.log
WorkflowError:
At least one job did not complete successfully.
````
The weird thing is that I got the output, so I'm going to leave it like that, and go further with the tutorial. 

#### Visualizing the DAG 
DAG = directed acyclic graph
You can look at the dependancies as each being nodes, in a graph or pipeline and it's directed, from input to output 

To do this you should install 
````
mamba install -c conda-forge graphviz
````
Again, I didn't do this because of the server 
But I treid the following command on the server: 
````
snakemake --dag targets | dot -Tpng > dag.png
````
dot will take the notation and render it als a png and redirect it to a file output 

It didn't work, maybe I will try it later in WSL. 

#### Clean up
It created **/home/genomics/mhannaert/Tutorial_snakemake/tutorial_drought_index/.snakemake**
This keeps track of all the information about running snakemake, things like log files,... It can get realy big -> important to add it to .gitignore because it is to big 
now you can add everything to github  







