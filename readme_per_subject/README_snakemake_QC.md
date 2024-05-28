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
