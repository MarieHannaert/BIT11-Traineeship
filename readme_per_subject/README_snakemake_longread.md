# Snakemake Longreads
I will make a snakemake pipeline from my bash script **/home/genomics/mhannaert/scripts/complete_longread.sh** and I will use my illumina snakemake as example. 

## setting up the snakemake enviroment
The structure I need in the enviroment: 
````
snakemake/
├─ Longreadpipeline/
|  ├─ .snakemake
│  ├─ data/
|  |  ├─sampels/
|  ├─ envs
|  ├─ snakefile
|  ├─ LICENSE
|  ├─ Scripts/
│  ├─ README
````
I made this: **/home/genomics/mhannaert/snakemake**

## snakefile 
The first step is reading in the data. 
````
import os

# Define directories
REFDIR = os.getcwd()
#print(REFDIR)
sample_dir = REFDIR+"/data/samples"

sample_names = []
sample_list = os.listdir(sample_dir)
for i in range(len(sample_list)):
    sample = sample_list[i]
    if sample.endswith(".fq.gz"):
        samples = sample.split(".fq")[0]
        sample_names.append(samples)
        print(sample_names)
````
I just needed to remove the condition, because longreads don't have multiple conditions, it's just one file. 

### nanoplot
I added the part for nanoplot: 
````
rule all:
    input:
        "results/01_nanoplot/NanoPlot-report.html"

rule nanoplot:
    input:
        expand("data/samples/{names}.fq.gz", names=sample_names)
    output: 
        "results/01_nanoplot/NanoPlot-report.html",
        result = directory("results/01_nanoplot/")
    log:
        "logs/nanoplot.log"
    params:
        extra="-t 2"
    conda:
        "envs/nanoplot.yaml"
    shell:
        """
        NanoPlot {params.extra} --fastq data/samples/*.fq.gz -o {output.result} --maxlength 40000 --plots --legacy hex dot 2>> {log}
        """
````
I tested it with a dry run snakemake -np and it gave a nice output. 

### filtlong
This is what I added: 
````
rule filtlong:
    input:
        "data/samples/{names}.fq.gz"
    output: 
        "02_filtlong/{names}_1000bp_100X.fq.gz"
    log:
        "logs/filtlong_{names}.log"
    params:
        extra="--min_length 1000 --target_bases 540000000"
    conda:
        "envs/filtlong.yaml"
    shell:
        """
        filtlong {params.extra} {input} |  gzip > {output} 2>> {log}
        """
````
I did again a dry run, and that worked, I will now test a real run before I add a longer step. 
SUCCES! 
 ### Porechop
 for porechop the samples need to be unzipped so I splitted that part in to two rules:
 ````
 rule unzip:
    input:
        "data/samples/{names}.fq.gz",
        expand("results/02_filtlong/{names}_1000bp_100X.fq.gz", names=sample_names)
    output:
        "data/samples/{names}.fq"
    shell: 
        """
            pigz -dk {input[0]}
        """
rule porechop: 
    input:
        "data/samples/{names}.fq"
    output:
        "results/03_porechopABI/{names}_trimmed.fq"
    log:
        "logs/porechop_{names}.log"
    params:
        extra="-abi -t 32 -v 2"
    conda:
        "envs/porechop.yaml"
    shell:
        """
        porechop_abi {params.extra} -i {input} -o {output} 2>> {log}
        """
 ````
 I test a dry run: 
 ````
 Job stats:
job         count
--------  -------
all             1
filtlong        2
nanoplot        1
porechop        2
unzip           2
total           8

Reasons:
    (check individual jobs above for details)
    code has changed since last execution:
        unzip
    input files updated by another job:
        all, porechop, unzip
    output files have to be generated:
        filtlong, nanoplot, porechop, unzip
Some jobs were triggered by provenance information, see 'reason' section in the rule displays above.
If you prefer that only modification time is used to determine whether a job shall be executed, use the command line option '--rerun-triggers mtime' (also see --help).
If you are sure that a change for a certain output file (say, <outfile>) won't change the result (e.g. because you just changed the formatting of a script or environment definition), you can also wipe its metadata to skip such a trigger via 'snakemake --cleanup-metadata <outfile>'. 
Rules with provenance triggered jobs: unzip


This was a dry-run (flag -n). The order of jobs does not reflect the order of execution.
 ````
 This looks good, so now a real test: 
 ````
 WorkflowError:
Failed to open source file /home/genomics/mhannaert/snakemake/Longreadpipeline/envs/porechop.yaml
FileNotFoundError: [Errno 2] No such file or directory: '/home/genomics/mhannaert/snakemake/Longreadpipeline/envs/porechop.yaml'
 ````
 I forgot to add my conda env 
 So now a real test, after I added my conda env: 
 ````
 [Mon May 27 16:46:28 2024]
localrule all:
    input: results/01_nanoplot/NanoPlot-report.html, results/02_filtlong/GBBC502_1000bp_100X.fq.gz, results/02_filtlong/GBBC_504_sup_1000bp_100X.fq.gz, results/03_porechopABI/GBBC502_trimmed.fq, results/03_porechopABI/GBBC_504_sup_trimmed.fq
    jobid: 0
    reason: Input files updated by another job: results/03_porechopABI/GBBC_504_sup_trimmed.fq, results/03_porechopABI/GBBC502_trimmed.fq, results/01_nanoplot/NanoPlot-report.html, results/02_filtlong/GBBC502_1000bp_100X.fq.gz, results/02_filtlong/GBBC_504_sup_1000bp_100X.fq.gz
    resources: tmpdir=/tmp

[Mon May 27 16:46:28 2024]
Finished job 0.
8 of 8 steps (100%) done
Complete log: .snakemake/log/2024-05-27T160948.096023.snakemake.log
 ````
This worked
### Flye
This is first reformatiing and then performing fly, so I did it in two rules: 
````
rule reformat:
    input:
        "results/03_porechopABI/{names}_trimmed.fq"
    output:
        "results/04_reformat/{names}_OUTPUT.fasta"
    shell:
        """
        cat {input} | awk '{if(NR%4==1) {printf(">%s\n",substr($0,2));} else if(NR%4==2) print;}' > {output}
        """
rule Flye:
    input: 
        "results/04_reformat/{names}_OUTPUT.fasta"
    output:
        directory("results/04_flye/flye_out_{names}")
    log:
        "logs/flye_{names}.log"
    params:
        extra="--threads 32 --iterations 1 --scaffold"
    conda: 
        "envs/flye.yaml"
    shell:
        """
        flye --asm-coverage 50 --genome-size 5.4g --nano-hq {input} --out-dir {output} {params.extra} 2>> {log}
        """
````
### Racon
I must first do the minimap and then the racon, so the next part in the Snakefile looks like this:
````
rule minimap2:
    input: 
        porechop=expand("results/03_porechopABI/{names}_OUTPUT.fasta",names=sample_names),
        flye=expand("results/04_flye/flye_out_names/assembly.fasta", names=sample_names)
    output:
        "results/05_racon/{names}_aln.paf.gz"
    log:
        "logs/minimap2_{names}.log"
    params:
        extra="-t 16 -x map-ont -secondary=no -m 100"
    conda: 
        "envs/minimap2.yaml"
    shell:
        """
        minimap2 {params.extra} {input.flye} {input.porechop} | gzip - > {output} 2>> {log}
        """
rule racon:
    input: 
        porechop=expand("results/03_porechopABI/{names}_OUTPUT.fasta",names=sample_names),
        flye=expand("results/04_flye/flye_out_names/assembly.fasta", names=sample_names),
        minimap=expand("results/05_racon/{names}_aln.paf.gz", names=sample_names)
    output:
        "results/05_racon/names_racon.fasta"
    log:
        "logs/racon_{names}.log"
    params:
        extra="-u -t 16"
    shell:
        """
        racon {params.extra} {input.porechop} {input.minimap} {input.flye} > {output} 2>> {log}
        """
````
I will dry run it:
````
Building DAG of jobs...
Job stats:
job         count
--------  -------
all             1
flye            2
minimap2        2
racon           2
reformat        2
total           9

Execute 2 jobs...

[Mon May 27 17:14:52 2024]
rule reformat:
    input: results/03_porechopABI/GBBC_504_sup_trimmed.fq
    output: results/03_porechopABI/GBBC_504_sup_OUTPUT.fasta
    jobid: 10
    reason: Missing output files: results/03_porechopABI/GBBC_504_sup_OUTPUT.fasta
    wildcards: names=GBBC_504_sup
    resources: tmpdir=<TBD>

RuleException in rule reformat in file /home/genomics/mhannaert/snakemake/Longreadpipeline/Snakefile, line 80:
ValueError: unexpected '{' in field name, when formatting the following:

        cat {input} | awk '{if(NR%4==1) {printf(">%s
",substr($0,2));} else if(NR%4==2) print;}' > {output}
````
This is not a nice error, I will sove it tommorw 
