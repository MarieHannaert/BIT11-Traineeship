# Snakemake QC pipeline
Based on the **snakemake/README_snakemake_hybride.md** information, we decided to make this snakemake. This snakemake will include: skANI, Quast, Busco, but my supervisor also told to include: checkM and checkM2, because these also do controle on contamination. The goal of this snakemake is that it can be used for multiple projects and not only the project of Sourcetrack, so that it is a very general snakemake. 

## setting up the snakemake enviroment
The structure I need in the enviroment: 
````
snakemake/
├─ Hybridepipeline/
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
So reading in the data. 
````
import os

# Define directories
REFDIR = os.getcwd()
#print(REFDIR)
sample_dir = REFDIR+"/data/assemblies"

sample_names = []
sample_list = os.listdir(sample_dir)
for i in range(len(sample_list)):
    sample = sample_list[i]
    if sample.endswith(".fna"):
        samples = sample.split(".fna")[0]
        sample_names.append(samples)
        print(sample_names)
````
 
I runned this already and it gave the nice output.
So that's a good sign. 

Now I added the part for skANI, Quast, buso 
````
rule all:
    input:
        "results/skani/skani_results_file.txt",
        "results/quast/quast_summary_table.txt",
        "results/skani/skANI_Quast_output.xlsx",
        "results/quast/beeswarm_vis_assemblies.png",
        "results/busco_summary"

rule skani:
    input:
        expand("data/assemblies/{names}.fna", names=sample_names)
    output:
        result = "results/skani/skani_results_file.txt"
    params:
        extra = "-t 32 -n 1"
    log:
        "logs/skani.log"
    conda:
       "envs/skani.yaml"
    shell:
        """
        skani search {input} -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o {output} {params.extra} 2>> {log}
        """
rule quast:
    input:
        "data/assemblies/{names}.fna"
    output:
        directory("results/quast/{names}/")
    log:
        "logs/quast_{names}.log"
    conda:
        "envs/quast.yaml"
    shell:
        """
        quast.py {input} -o {output} 2>> {log}
        """
rule summarytable:
    input:
        expand("results/quast/{names}", names = sample_names)
    output: 
        "results/quast/quast_summary_table.txt"
    shell:
        """
        touch {output}
        echo -e "Assembly\tcontigs (>= 0 bp)\tcontigs (>= 1000 bp)\tcontigs (>= 5000 bp)\tcontigs (>= 10000 bp)\tcontigs (>= 25000 bp)\tcontigs (>= 50000 bp)\tTotal length (>= 0 bp)\tTotal length (>= 1000 bp)\tTotal length (>= 5000 bp)\tTotal length (>= 10000 bp)\tTotal length (>= 25000 bp)\tTotal length (>= 50000 bp)\tcontigs\tLargest contig\tTotal length\tGC (%)\tN50\tN90\tauN\tL50\tL90\tN's per 100 kbp" >> {output}
        # Initialize a counter
        counter=1

        # Loop over all the transposed_report.tsv files and read them
        for file in $(find -type f -name "transposed_report.tsv"); do
            # Show progress
            echo "Processing file: $counter"

            # Add the content of each file to the summary table (excluding the header)
            tail -n +2 "$file" >> {output}

            # Increment the counter
            counter=$((counter+1))
        done
        """
rule xlsx:
    input:
        "results/quast/quast_summary_table.txt",
        "results/skani/skani_results_file.txt"
    output:
        "results/skani/skANI_Quast_output.xlsx"
    shell:
        """
          scripts/skani_quast_to_xlsx.py results/
          mv results/skANI_Quast_output.xlsx results/skani/
        """

rule beeswarm:
    input:
        "results/quast/quast_summary_table.txt"
    output:
        "results/quast/beeswarm_vis_assemblies.png"
    conda:
        "envs/beeswarm.yaml"
    shell: 
        """
            scripts/beeswarm_vis_assemblies.R {input}
            mv beeswarm_vis_assemblies.png results/quast/
        """
rule busco:
    input: 
        "data/assemblies/{names}.fna"
    output:
        directory("results/busco/{names}")
    params:
        extra= "-m genome --auto-lineage-prok -c 32"
    log: 
        "logs/busco_{names}.log"
    conda:
        "envs/busco.yaml"
    shell:
        """
        busco -i {input} -o {output} {params.extra} 2>> {log}
        """
rule buscosummary:
    input:
        expand("results/busco/{names}", names=sample_names)
    output:
        directory("results/busco_summary")
    conda:
        "envs/busco.yaml"
    shell:
        """
        scripts/busco_summary.sh results/busco_summary
        """
````
I also went changing the script so that they are correct with these directory names. 
I did a dry ruyn and that gave the following output: 
````
['070_001_240321_001_0356_099_01_4691']
['070_001_240321_001_0356_099_01_4691', '070_001_240321_001_0355_099_01_4691']
Building DAG of jobs...
Job stats:
job             count
------------  -------
all                 1
beeswarm            1
busco               2
buscosummary        1
quast               2
skani               1
summarytable        1
xlsx                1
total              10

Execute 5 jobs...

[Tue May 28 16:18:17 2024]
rule skani:
    input: data/assemblies/070_001_240321_001_0356_099_01_4691.fna, data/assemblies/070_001_240321_001_0355_099_01_4691.fna
    output: results/skani/skani_results_file.txt
    log: logs/skani.log
    jobid: 1
    reason: Missing output files: results/skani/skani_results_file.txt
    resources: tmpdir=<TBD>


        skani search data/assemblies/070_001_240321_001_0356_099_01_4691.fna data/assemblies/070_001_240321_001_0355_099_01_4691.fna -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o results/skani/skani_results_file.txt -t 32 -n 1 2>> logs/skani.log


[Tue May 28 16:18:17 2024]
rule quast:
    input: data/assemblies/070_001_240321_001_0355_099_01_4691.fna
    output: results/quast/070_001_240321_001_0355_099_01_4691
    log: logs/quast_070_001_240321_001_0355_099_01_4691.log
    jobid: 4
    reason: Missing output files: results/quast/070_001_240321_001_0355_099_01_4691
    wildcards: names=070_001_240321_001_0355_099_01_4691
    resources: tmpdir=<TBD>


        quast.py data/assemblies/070_001_240321_001_0355_099_01_4691.fna -o results/quast/070_001_240321_001_0355_099_01_4691 2>> logs/quast_070_001_240321_001_0355_099_01_4691.log


[Tue May 28 16:18:17 2024]
rule busco:
    input: data/assemblies/070_001_240321_001_0355_099_01_4691.fna
    output: results/busco/070_001_240321_001_0355_099_01_4691
    log: logs/busco_070_001_240321_001_0355_099_01_4691.log
    jobid: 9
    reason: Missing output files: results/busco/070_001_240321_001_0355_099_01_4691
    wildcards: names=070_001_240321_001_0355_099_01_4691
    resources: tmpdir=<TBD>


        busco -i data/assemblies/070_001_240321_001_0355_099_01_4691.fna -o results/busco/070_001_240321_001_0355_099_01_4691 -m genome --auto-lineage-prok -c 32 2>> logs/busco_070_001_240321_001_0355_099_01_4691.log


[Tue May 28 16:18:17 2024]
rule busco:
    input: data/assemblies/070_001_240321_001_0356_099_01_4691.fna
    output: results/busco/070_001_240321_001_0356_099_01_4691
    log: logs/busco_070_001_240321_001_0356_099_01_4691.log
    jobid: 8
    reason: Missing output files: results/busco/070_001_240321_001_0356_099_01_4691
    wildcards: names=070_001_240321_001_0356_099_01_4691
    resources: tmpdir=<TBD>


        busco -i data/assemblies/070_001_240321_001_0356_099_01_4691.fna -o results/busco/070_001_240321_001_0356_099_01_4691 -m genome --auto-lineage-prok -c 32 2>> logs/busco_070_001_240321_001_0356_099_01_4691.log


[Tue May 28 16:18:17 2024]
rule quast:
    input: data/assemblies/070_001_240321_001_0356_099_01_4691.fna
    output: results/quast/070_001_240321_001_0356_099_01_4691
    log: logs/quast_070_001_240321_001_0356_099_01_4691.log
    jobid: 3
    reason: Missing output files: results/quast/070_001_240321_001_0356_099_01_4691
    wildcards: names=070_001_240321_001_0356_099_01_4691
    resources: tmpdir=<TBD>


        quast.py data/assemblies/070_001_240321_001_0356_099_01_4691.fna -o results/quast/070_001_240321_001_0356_099_01_4691 2>> logs/quast_070_001_240321_001_0356_099_01_4691.log

Execute 2 jobs...

[Tue May 28 16:18:17 2024]
rule summarytable:
    input: results/quast/070_001_240321_001_0356_099_01_4691, results/quast/070_001_240321_001_0355_099_01_4691
    output: results/quast/quast_summary_table.txt
    jobid: 2
    reason: Missing output files: results/quast/quast_summary_table.txt; Input files updated by another job: results/quast/070_001_240321_001_0355_099_01_4691, results/quast/070_001_240321_001_0356_099_01_4691
    resources: tmpdir=<TBD>


        touch results/quast/quast_summary_table.txt
        echo -e "Assembly       contigs (>= 0 bp)       contigs (>= 1000 bp)    contigs (>= 5000 bp)    contigs (>= 10000 bp)   contigs (>= 25000 bp)   contigs (>= 50000 bp)   Total length (>= 0 bp) Total length (>= 1000 bp)       Total length (>= 5000 bp)       Total length (>= 10000 bp)      Total length (>= 25000 bp)      Total length (>= 50000 bp)      contigsLargest contig  Total length    GC (%)  N50     N90     auN     L50     L90     N's per 100 kbp" >> results/quast/quast_summary_table.txt
        # Initialize a counter
        counter=1

        # Loop over all the transposed_report.tsv files and read them
        for file in $(find -type f -name "transposed_report.tsv"); do
            # Show progress
            echo "Processing file: $counter"

            # Add the content of each file to the summary table (excluding the header)
            tail -n +2 "$file" >> results/quast/quast_summary_table.txt

            # Increment the counter
            counter=$((counter+1))
        done


[Tue May 28 16:18:17 2024]
rule buscosummary:
    input: results/busco/070_001_240321_001_0356_099_01_4691, results/busco/070_001_240321_001_0355_099_01_4691
    output: results/busco_summary
    jobid: 7
    reason: Missing output files: results/busco_summary; Input files updated by another job: results/busco/070_001_240321_001_0355_099_01_4691, results/busco/070_001_240321_001_0356_099_01_4691
    resources: tmpdir=<TBD>


        scripts/busco_summary.sh results/busco_summary

Execute 2 jobs...

[Tue May 28 16:18:17 2024]
rule xlsx:
    input: results/quast/quast_summary_table.txt, results/skani/skani_results_file.txt
    output: results/skani/skANI_Quast_output.xlsx
    jobid: 5
    reason: Missing output files: results/skani/skANI_Quast_output.xlsx; Input files updated by another job: results/quast/quast_summary_table.txt, results/skani/skani_results_file.txt
    resources: tmpdir=<TBD>


          scripts/skani_quast_to_xlsx.py results/
          mv results/skANI_Quast_output.xlsx results/skani/


[Tue May 28 16:18:17 2024]
rule beeswarm:
    input: results/quast/quast_summary_table.txt
    output: results/quast/beeswarm_vis_assemblies.png
    jobid: 6
    reason: Missing output files: results/quast/beeswarm_vis_assemblies.png; Input files updated by another job: results/quast/quast_summary_table.txt
    resources: tmpdir=<TBD>


            scripts/beeswarm_vis_assemblies.R results/quast/quast_summary_table.txt
            mv beeswarm_vis_assemblies.png results/quast/

Execute 1 jobs...

[Tue May 28 16:18:17 2024]
rule all:
    input: results/skani/skani_results_file.txt, results/quast/quast_summary_table.txt, results/skani/skANI_Quast_output.xlsx, results/quast/beeswarm_vis_assemblies.png, results/busco_summary
    jobid: 0
    reason: Input files updated by another job: results/busco_summary, results/skani/skANI_Quast_output.xlsx, results/quast/beeswarm_vis_assemblies.png, results/quast/quast_summary_table.txt, results/skani/skani_results_file.txt
    resources: tmpdir=<TBD>

Job stats:
job             count
------------  -------
all                 1
beeswarm            1
busco               2
buscosummary        1
quast               2
skani               1
summarytable        1
xlsx                1
total              10

Reasons:
    (check individual jobs above for details)
    input files updated by another job:
        all, beeswarm, buscosummary, summarytable, xlsx
    output files have to be generated:
        beeswarm, busco, buscosummary, quast, skani, summarytable, xlsx

This was a dry-run (flag -n). The order of jobs does not reflect the order of execution.
````
so it looks like it works. 

I will now test it for real. 
It didn't work. 

## solving error
```
Assuming unrestricted shared filesystem usage.
Building DAG of jobs...
MissingInputException in rule buscosummary in file /home/genomics/mhannaert/snakemake/QCpipeline/Snakefile, line 116:
Missing input files for rule buscosummary:
    output: results/busco_summary
    affected files:
        results/08_busco/070_001_240321_001_0356_099_01_4691
        results/08_busco/070_001_240321_001_0355_099_01_4691
```
I changed a few thing like somewhere there was still a 08_busco, but that folder won't be made
and I runned again but: 
````
[Wed May 29 10:56:20 2024]
Error in rule busco:
    jobid: 8
    input: data/assemblies/070_001_240321_001_0356_099_01_4691.fna
    output: results/busco/070_001_240321_001_0356_099_01_4691
    log: logs/busco_070_001_240321_001_0356_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/QCpipeline/.snakemake/conda/199ca83dafe2436052f1cecb7442ba6b_
    shell:

        busco -i data/assemblies/070_001_240321_001_0356_099_01_4691.fna -o results/busco/070_001_240321_001_0356_099_01_4691 -m genome --auto-lineage-prok -c 32 2>> logs/busco_070_001_240321_001_0356_099_01_4691.log

        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Removing output files of failed job busco since they might be corrupted:
results/busco/070_001_240321_001_0356_099_01_4691
[Wed May 29 10:56:21 2024]
Error in rule busco:
    jobid: 9
    input: data/assemblies/070_001_240321_001_0355_099_01_4691.fna
    output: results/busco/070_001_240321_001_0355_099_01_4691
    log: logs/busco_070_001_240321_001_0355_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/QCpipeline/.snakemake/conda/199ca83dafe2436052f1cecb7442ba6b_
    shell:

        busco -i data/assemblies/070_001_240321_001_0355_099_01_4691.fna -o results/busco/070_001_240321_001_0355_099_01_4691 -m genome --auto-lineage-prok -c 32 2>> logs/busco_070_001_240321_001_0355_099_01_4691.log

        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Removing output files of failed job busco since they might be corrupted:
results/busco/070_001_240321_001_0355_099_01_4691
Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-29T105455.314041.snakemake.log
WorkflowError:
At least one job did not complete successfully.

In the logfile:
2024-05-29 10:56:20 ERROR:	md5 hash is incorrect: 7850d04d1eb3b0c81f6bf2d5860317cf while eba6a090cbe21abe1db69d841e8231bc expected
2024-05-29 10:56:21 ERROR:	[Errno 2] No such file or directory: '/home/genomics/mhannaert/snakemake/QCpipeline/busco_downloads/placement_files/supermatrix.aln.bacteria_odb10.2019-12-16.faa.tar.gz'
````
so it looks like something is wrong with the conda env, 
so I will replace that with a new one. 
I tested it:
````
2024-05-29 11:30:54 INFO:       Visit this page https://gitlab.com/ezlab/busco#how-to-cite-busco to see how to cite BUSCO
[Wed May 29 11:30:55 2024]
Finished job 8.
7 of 10 steps (70%) done
Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-29T112509.269955.snakemake.log
WorkflowError:
At least one job did not complete successfully.

logfile: 
EOFError: Compressed file ended before the end-of-stream marker was reached


2024-05-29 11:29:52 ERROR:	Compressed file ended before the end-of-stream marker was reached
2024-05-29 11:29:52 ERROR:	BUSCO analysis failed!
2024-05-29 11:29:52 ERROR:	Check the logs, read the user guide (https://busco.ezlab.org/busco_userguide.html), and check the BUSCO issue board on https://gitlab.com/ezlab/busco/issues

Error in rule busco:
    jobid: 9
    input: data/assemblies/070_001_240321_001_0355_099_01_4691.fna
    output: results/busco/070_001_240321_001_0355_099_01_4691
    log: logs/busco_070_001_240321_001_0355_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/QCpipeline/.snakemake/conda/199ca83dafe2436052f1cecb7442ba6b_
    shell:
        
        busco -i data/assemblies/070_001_240321_001_0355_099_01_4691.fna -o results/busco/070_001_240321_001_0355_099_01_4691 -m genome --auto-lineage-prok -c 32 2>> logs/busco_070_001_240321_001_0355_099_01_4691.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)
````
so One busco runned only and the summary wasn't done. 
The error is in the busco rule. 

## CheckM(2) 
My supervisor told me to add CheckM and CheckM2 to the QC pipeline. 
https://ecogenomics.github.io/CheckM/

https://github.com/Ecogenomics/CheckM
>CheckM provides a set of tools for assessing the quality of genomes recovered from isolates, single cells, or metagenomes. It provides robust estimates of genome completeness and contamination by using collocated sets of genes that are ubiquitous and single-copy within a phylogenetic lineage. Assessment of genome quality can also be examined using plots depicting key genomic characteristics (e.g., GC, coding density) which highlight sequences outside the expected distributions of a typical genome. CheckM also provides tools for identifying genome bins that are likely candidates for merging based on marker set compatibility, similarity in genomic characteristics, and proximity within a reference genome tree.

https://github.com/chklovski/CheckM2

>Rapid assessment of genome bin quality using machine learning.

>Unlike CheckM1, CheckM2 has universally trained machine learning models it applies regardless of taxonomic lineage to predict the completeness and contamination of genomic bins. This allows it to incorporate many lineages in its training set that have few - or even just one - high-quality genomic representatives, by putting it in the context of all other organisms in the training set.

I have also two howto files from my supervisor. The commands are: 
````
all parameters : checkm lineage_wf
Assume you have putative genomes in the directory /home/donovan/bins with fa as a the file extension and want to store the CheckM results in /home/donovan/checkm. To processes these genomes with 8 threads, simply run:
make a checkm folder, but genomes in bins folder
> checkm lineage_wf -t 24 -x fasta /home/genomics/sbaeyen/Pectobacterium/checkm/bins /home/genomics/sbaeyen/Pectobacterium/checkm
> checkm qa /home/genomics/sbaeyen/Pectobacterium/checkm/lineage.ms /home/genomics/sbaeyen/Pectobacterium/checkm/
make a checkm/plots folder
> checkm bin_qa_plot -x fasta ./checkm/ ./Pect_genomes/ready/ ./checkm/plots/
````
````
on WSL:
conda activate checkm2

checkm2 predict --threads 30 --input <folder_with_bins> --output-directory <output_folder> 

checkm2 predict --threads 8 --input GBBC3406.fna --output-directory GBBC3406_checkm2
````
### CheckM2
for checkm2 is this the rule that I added: 
````
rule checkM2:
    input:
        "data/assemblies/{names}.fna"
    output:
        directory("results/checkM2/{names}")
    params:
        extra="--threads 8"
    log:
        "logs/checkM2_{names}.log"
    conda:
        "envs/checkm2.yaml"
    shell:
        """
        checkm2 predict {params.extra} --input {input} --output-directory {output} 2>> {log}
        """
````
This didn't work: 
````
Error in rule checkM2:
    jobid: 10
    input: data/assemblies/070_001_240321_001_0356_099_01_4691.fna
    output: results/checkM2/070_001_240321_001_0356_099_01_4691
    log: logs/checkM2_070_001_240321_001_0356_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/QCpipeline/.snakemake/conda/5e00f98a73e68467497de6f423dfb41e_
    shell:
        
        checkm2 predict --threads 8 --input data/assemblies/070_001_240321_001_0356_099_01_4691.fna --output-directory results/checkM2/070_001_240321_001_0356_099_01_4691 2>> logs/checkM2_070_001_240321_001_0356_099_01_4691.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Removing output files of failed job checkM2 since they might be corrupted:
results/checkM2/070_001_240321_001_0356_099_01_4691
[Thu May 30 09:51:56 2024]
Error in rule checkM2:
    jobid: 11
    input: data/assemblies/070_001_240321_001_0355_099_01_4691.fna
    output: results/checkM2/070_001_240321_001_0355_099_01_4691
    log: logs/checkM2_070_001_240321_001_0355_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/QCpipeline/.snakemake/conda/5e00f98a73e68467497de6f423dfb41e_
    shell:
        
        checkm2 predict --threads 8 --input data/assemblies/070_001_240321_001_0355_099_01_4691.fna --output-directory results/checkM2/070_001_240321_001_0355_099_01_4691 2>> logs/checkM2_070_001_240321_001_0355_099_01_4691.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Removing output files of failed job checkM2 since they might be corrupted:
results/checkM2/070_001_240321_001_0355_099_01_4691
Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-30T095053.255635.snakemake.log
WorkflowError:
At least one job did not complete successfully.
````
In the log file can be found: 
````
[05/30/2024 09:51:56 AM] INFO: Running CheckM2 version 1.0.1
[05/30/2024 09:51:56 AM] INFO: Running quality prediction workflow with 8 threads.
[05/30/2024 09:51:56 AM] ERROR: DIAMOND database not found. Please download database using <checkm2 database --download>
````
I will perform this command: 
````
checkm2 database --download
````
I went inside the conda env: 
````
conda activate .snakemake/conda/5e00f98a73e68467497de6f423dfb41e_
checkm2 database --download
checkm2 testrun
````
````
[05/30/2024 10:20:06 AM] INFO: CheckM2 finished successfully.
[05/30/2024 10:20:06 AM] INFO: Test run successful! See README for details.
````
I tried this rule again:
````

[Thu May 30 10:23:47 2024]
Finished job 0.
3 of 3 steps (100%) done
Complete log: .snakemake/log/2024-05-30T102053.662019.snakemake.log
````
I went looking to the checkM2 output, and it looks qua styructure a bit like quast so I think its a good idea to make a summary and also add it in the excel. 
-> I will discuss this idea with my supervisor

### CheckM
for this rule I added: 
````
rule checkM:
    input:
        expand("data/assemblies/{names}.fna", names=sample_names)
    output:
        directory("results/checkm/{names}")
    params:
        extra="-t 24 -x fasta"
    log:
        "logs/checkM_{names}.log"
    conda:
        "envs/checkm.yaml"
    shell:
        """
        checkm lineage_wf {params.extra} {input} {output}
        """
````
I runned it and: 
````
It seems that the CheckM data folder has not been set yet or has been removed. Please run 'checkm data setRoot'.

Path [/home/mhannaert/.checkm] does not exist so I will attempt to create it
Path [/home/mhannaert/.checkm] has been created and you have permission to write to this folder.
(re) creating manifest file (please be patient).
usage: checkm
              {data,tree,tree_qa,lineage_set,taxon_list,taxon_set,analyze,qa,lineage_wf,taxonomy_wf,gc_plot,coding_plot,tetra_plot,dist_plot,gc_bias_plot,nx_plot,len_hist,marker_plot,unbinned,coverage,tetra,profile,ssu_finder,merge,outliers,modify,unique,test}
              ...
checkm: error: unrecognized arguments: results/checkm/070_001_240321_001_0356_099_01_4691
usage: checkm
              {data,tree,tree_qa,lineage_set,taxon_list,taxon_set,analyze,qa,lineage_wf,taxonomy_wf,gc_plot,coding_plot,tetra_plot,dist_plot,gc_bias_plot,nx_plot,len_hist,marker_plot,unbinned,coverage,tetra,profile,ssu_finder,merge,outliers,modify,unique,test}
              ...
checkm: error: unrecognized arguments: results/checkm/070_001_240321_001_0355_099_01_4691
[Thu May 30 10:49:24 2024]
Error in rule checkM:
    jobid: 11
    input: data/assemblies/070_001_240321_001_0356_099_01_4691.fna, data/assemblies/070_001_240321_001_0355_099_01_4691.fna
    output: results/checkm/070_001_240321_001_0355_099_01_4691
    log: logs/checkM_070_001_240321_001_0355_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/QCpipeline/.snakemake/conda/fc1c0b2ff8156a2c81f4d97546659744_
    shell:
        
        checkm lineage_wf -t 24 -x fasta data/assemblies/070_001_240321_001_0356_099_01_4691.fna data/assemblies/070_001_240321_001_0355_099_01_4691.fna results/checkm/070_001_240321_001_0355_099_01_4691
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

[Thu May 30 10:49:24 2024]
Error in rule checkM:
    jobid: 10
    input: data/assemblies/070_001_240321_001_0356_099_01_4691.fna, data/assemblies/070_001_240321_001_0355_099_01_4691.fna
    output: results/checkm/070_001_240321_001_0356_099_01_4691
    log: logs/checkM_070_001_240321_001_0356_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/QCpipeline/.snakemake/conda/fc1c0b2ff8156a2c81f4d97546659744_
    shell:
        
        checkm lineage_wf -t 24 -x fasta data/assemblies/070_001_240321_001_0356_099_01_4691.fna data/assemblies/070_001_240321_001_0355_099_01_4691.fna results/checkm/070_001_240321_001_0356_099_01_4691
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-30T104920.337152.snakemake.log
WorkflowError:
At least one job did not complete successfully.
````
I think for the output it can just be chekm directory and not per sample. 
I changed it to the following: 
````
rule checkM:
    input:
       "data/assemblies"
    output:
        directory("results/checkm/")
    params:
        extra="-t 24 -x fasta"
    log:
        "logs/checkM.log"
    conda:
        "envs/checkm.yaml"
    shell:
        """
        checkm lineage_wf {params.extra} {input} {output}
        """
````
BUt still didn't work, I also forgot to add the log file to the command. 
I went looking in the documentation again and i see were I made a mistake, you need to specify the type of extension, here it's fasta, but my files are fna. 
I changed it, but the error I get is an error about the output. 
so they talked the whole time about the bins folder, now I understand how the structure must be 
I need to make a checkm directory with in there a bins diretory with the samples. 
````
rule prepare_checkm:
    input:
        expand("data/assemblies/{names}.fna", names=sample_names)
    output: 
        expand("results/checkm/bins/{names}.fna", names=sample_names)
    shell: 
        """
        cp {input} {output}
        """

rule checkM:
    input:
        expand("results/checkm/bins/{names}.fna", names=sample_names)
    output:
        "results/checkm/lineage.ms",
        dir=directory("results/checkm")
    params:
        extra="-t 24"
    log:
        "logs/checkM.log"
    conda:
        "envs/checkm.yaml"
    shell:
        """
        mkdir -p {output}
        checkm lineage_wf {params.extra} {input} {output.dir} 2>> {log}
        """
````
````
ChildIOException:
File/directory is a child to another output:
('/home/genomics/mhannaert/snakemake/QCpipeline/results/checkm', checkM)
('/home/genomics/mhannaert/snakemake/QCpipeline/results/checkm/bins/070_001_240321_001_0355_099_01_4691.fna', prepare_checkm)
````
When I look at the error: 
````
 checkm lineage_wf -t 24 data/assemblies/070_001_240321_001_0356_099_01_4691.fna data/assemblies/070_001_240321_001_0355_099_01_4691.fna results/checkm 2>> logs/checkM.log
````
I unerstood something wrong, when they talked about bins in the documentation this isn't a file, this is just an other name for assembly file. So I don't need all the files as input, but only one, so the exapand needed to go. I removed this and changed the rule and test again:

````
[2024-05-30 13:42:40] INFO: CheckM v1.2.2
[2024-05-30 13:42:40] INFO: checkm lineage_wf -t 24 data/assemblies/070_001_240321_001_0355_099_01_4691.fna results/checkm/070_001_240321_001_0355_099_01_4691
[2024-05-30 13:42:40] INFO: CheckM data: /home/mhannaert/.checkm
[2024-05-30 13:42:40] INFO: [CheckM - tree] Placing bins in reference genome tree.
[2024-05-30 13:42:40] INFO: CheckM v1.2.2
[2024-05-30 13:42:40] INFO: checkm lineage_wf -t 24 data/assemblies/070_001_240321_001_0356_099_01_4691.fna results/checkm/070_001_240321_001_0356_099_01_4691
[2024-05-30 13:42:40] INFO: CheckM data: /home/mhannaert/.checkm
[2024-05-30 13:42:40] INFO: [CheckM - tree] Placing bins in reference genome tree.

Unexpected error: <class 'IndexError'>

Unexpected error: <class 'IndexError'>
````
In the log file I could find: "IndexError: list index out of range"
I searched the error online and found an aswer: 
>I just had this issue as well. Giving CheckM a directory rather than a single FASTA file solved it!

so it needs to be a directory

## test run
again the following busco error: 
````
2024-05-30 14:04:01 ERROR:	md5 hash is incorrect: c4f2541319bd5212d8f43e845646bad7 while 3eb26c670c520c0f3b32bff46fce03d7 expected
````
I deleted all the output, logs/ results/ .snakemake/ 
and run again:
````
Error in rule checkM:
    jobid: 10
    input: data/assemblies
    output: results/checkm
    log: logs/checkM.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/QCpipeline/.snakemake/conda/fc1c0b2ff8156a2c81f4d97546659744_
    shell:
        
        checkm lineage_wf -t 24 data/assemblies results/checkm 2>> logs/checkM.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Error in rule checkM2:
    jobid: 12
    input: data/assemblies/070_001_240321_001_0355_099_01_4691.fna
    output: results/checkM2/070_001_240321_001_0355_099_01_4691
    log: logs/checkM2_070_001_240321_001_0355_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/QCpipeline/.snakemake/conda/5e00f98a73e68467497de6f423dfb41e_
    shell:
        
        checkm2 predict --threads 8 --input data/assemblies/070_001_240321_001_0355_099_01_4691.fna --output-directory results/checkM2/070_001_240321_001_0355_099_01_4691 2>> logs/checkM2_070_001_240321_001_0355_099_01_4691.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

````

I still got some errors in the following rules: 
- checkM
- checkM2
: 
````
[Thu May 30 14:31:13 2024]
Finished job 8.
5 of 13 steps (38%) done
[Thu May 30 14:32:35 2024]
Finished job 11.
6 of 13 steps (46%) done
````
I went looking in all the log files, skANI did it perfect, quast has also runned perfectly, Busco also worked, but
checkM it worked but every time there is this error: FileNotFoundError: [Errno 2] No such file or directory: '/home/mhannaert/.checkm/hmms/phylo.hmm'
checkm2 only runned on one sample. 
And all of the visualisations weren't done. 

I read the documentation of checkM and there is a test installation and I will try that to see if it's the installation is correct: 
````
checkm test ~/checkm_test_results
````
The problem is that I miss some input files: 
[2024-05-30 14:50:11] ERROR: Input file does not exists: /home/mhannaert/.checkm/test_data/637000110.fna

so I will now search how to install these:
````
$ mkdir checkm_data
$ cd checkm_data
$ wget https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
$ tar -xvzf checkm_data_2015_01_16.tar.gz 
$rm checkm_data_2015_01_16.tar.gz 
$ cd ..
$ export CHECKM_DATA_PATH=<your own path>/snakemake/QCpipeline/checkm_data/
$ checkm data setRoot <your own path>/snakemake/QCpipeline/checkm_data/
````
I test it again now I installed this. 
with 
````
checkm test ~/checkm_test_results
````
This worked now, so now I will rerun my snakemake. 
This worked, I only had one error that I forgot to flag my directory in the output of rule checkM. 
So this worked and is ready for a readme. 

## adding checkM2 to xlsx 
First I will add a rule for a summary: 
````
rule summarytable_CheckM2:
    input:
        expand("results/checkM2/{names}", names = sample_names)
    output: 
        "results/checkM2/checkM2_summary_table.txt"
    shell:
        """
        touch {output}
        echo -e "Name\tCompleteness\tContamination\tCompleteness_Model_Used\tTranslation_Table_Used\tCoding_Density\tContig_N50\tAverage_Gene_Length\tGenome_Size\tGC_Content\tTotal_Coding_Sequences\tAdditional_Notes">> {output}
        # Initialize a counter
        counter=1

        # Loop over all the transposed_report.tsv files and read them
        for file in $(find -type f -name "quality_report.tsv"); do
            # Show progress
            echo "Processing file: $counter"

            # Add the content of each file to the summary table (excluding the header)
            tail -n +2 "$file" >> {output}

            # Increment the counter
            counter=$((counter+1))
        done
        """
````
and then I moved the xlsx rule and changed it a bit: 
````
rule xlsx:
    input:
        "results/quast/quast_summary_table.txt",
        "results/skani/skani_results_file.txt",
        "results/checkM2/checkM2_summary_table.txt"
    output:
        "results/skANI_Quast_checkM2_output.xlsx"
    shell:
        """
        scripts/skani_quast_checkm2_to_xlsx.py results/
        """
````
I runned this and it worked. 
## DAG and report
I made a dag and report and also tried the "--linter" option
````
snakemake --report report.html
snakemake --rulegraph | dot -Tsvg > dag_simple.svg
snakemake --dag | dot -Tsvg > dag.svg
````

When I looked at the DAG schema I saw a lot of links that were not nessecar, so I thin k there is to much in my rule all, and I think this problem is by every snakefile of me. 
so I will delete all the unessary thing out of my rule all in my snakefiles. 


> Snakemake (>=5.11) comes with a code quality checker (a so called linter), that analyzes your workflow and highlights issues that should be solved in order to follow best practices, achieve maximum readability, and reproducibility. The linter can be invoked with
````
snakemake --lint
````
Output: 
````
snakemake --lint
Lints for snakefile /home/genomics/mhannaert/snakemake/QCpipeline/Snakefile:
    * Absolute path "/data/assemblies" in line 6:
      Do not define absolute paths inside of the workflow, since this renders your workflow irreproducible on other machines. Use path relative to the working directory instead, or
      make the path configurable via a config file.
      Also see:
      https://snakemake.readthedocs.io/en/latest/snakefiles/configuration.html#configuration
    * Path composition with '+' in line 6:
      This becomes quickly unreadable. Usually, it is better to endure some redundancy against having a more readable workflow. Hence, just repeat common prefixes. If path composition
      is unavoidable, use pathlib or (python >= 3.6) string formatting with f"...".
      Also see:


Lints for rule summarytable (line 105, /home/genomics/mhannaert/snakemake/QCpipeline/Snakefile):
    * No log directive defined:
      Without a log directive, all output will be printed to the terminal. In distributed environments, this means that errors are harder to discover. In local environments, output of
      concurrent jobs will be mixed and become unreadable.
      Also see:
      https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#log-files
    * Specify a conda environment or container for each rule.:
      This way, the used software for each specific step is documented, and the workflow can be executed on any machine without prerequisites.
      Also see:
      https://snakemake.readthedocs.io/en/latest/snakefiles/deployment.html#integrated-package-management
      https://snakemake.readthedocs.io/en/latest/snakefiles/deployment.html#running-jobs-in-containers

Lints for rule beeswarm (line 159, /home/genomics/mhannaert/snakemake/QCpipeline/Snakefile):
    * No log directive defined:
      Without a log directive, all output will be printed to the terminal. In distributed environments, this means that errors are harder to discover. In local environments, output of
      concurrent jobs will be mixed and become unreadable.
      Also see:
      https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#log-files

Lints for rule buscosummary (line 229, /home/genomics/mhannaert/snakemake/QCpipeline/Snakefile):
    * No log directive defined:
      Without a log directive, all output will be printed to the terminal. In distributed environments, this means that errors are harder to discover. In local environments, output of
      concurrent jobs will be mixed and become unreadable.
      Also see:
      https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#log-files

Lints for rule summarytable_CheckM2 (line 340, /home/genomics/mhannaert/snakemake/QCpipeline/Snakefile):
    * No log directive defined:
      Without a log directive, all output will be printed to the terminal. In distributed environments, this means that errors are harder to discover. In local environments, output of
      concurrent jobs will be mixed and become unreadable.
      Also see:
      https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#log-files
    * Specify a conda environment or container for each rule.:
      This way, the used software for each specific step is documented, and the workflow can be executed on any machine without prerequisites.
      Also see:
      https://snakemake.readthedocs.io/en/latest/snakefiles/deployment.html#integrated-package-management
      https://snakemake.readthedocs.io/en/latest/snakefiles/deployment.html#running-jobs-in-containers

Lints for rule xlsx (line 394, /home/genomics/mhannaert/snakemake/QCpipeline/Snakefile):
    * No log directive defined:
      Without a log directive, all output will be printed to the terminal. In distributed environments, this means that errors are harder to discover. In local environments, output of
      concurrent jobs will be mixed and become unreadable.
      Also see:
      https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#log-files
    * Specify a conda environment or container for each rule.:
      This way, the used software for each specific step is documented, and the workflow can be executed on any machine without prerequisites.
      Also see:
      https://snakemake.readthedocs.io/en/latest/snakefiles/deployment.html#integrated-package-management
      https://snakemake.readthedocs.io/en/latest/snakefiles/deployment.html#running-jobs-in-containers
````
Maybe I will redo this tommorow to solve all this remarks. 

## readme
Because everything worked I will now wright the readme file for the github repository. 
I need to specify that it's a quality pipeline for bacterial genomes, that can be perfomed after the assembly is done. 

I also need to specify the installation and downloads I did for checkM and checkM2. The rest I will reuse from the other readme files. 

The result can be seen in the git repository: **Assembly_QC_Snakemake/**