# Define list of conditions
IDS, = glob_wildcards("{id}_1.fq.gz")
CONDITIONS = ["1", "2"]

# Define directories
REFDIR = "/home/genomics/mhannaert/snakemake/Illuminapipeline/"
SAMDIR = REFDIR + "/data/samples/"
RESDIR = "/results"
DIRS = ["00_fastqc/","01_multiqc/"]
#,"02_kraken2/","03_krona/"
rule all:
    input: 
        expand("results/{dirs}", dirs= DIRS)

# Rule to perform FastQC analysis
rule fastqc:
    input:
        expand(REFDIR+"{id}_{con}.fq.gz", id= IDS, con=CONDITIONS)
    output:
        directory("results/00_fastqc/")
    log:
        "logs/fastqc/"
    params:
        extra="-t 32",

    shell:
        """
        fastqc {params.extra} {input} --extract -o {output} 2>> {log}
        """

rule multiqc:
    input:
        "results/00_fastqc/"
    output:
        directory("results/01_multiqc/")
    log:
        "logs/multiqc.log"
    conda:
        "envs/multiqc.yml"
    shell:
        """
        multiqc {input} 2>> {log}
        rm -rf {input} 2>> {log}
        mv {input}/multiqc_report.html {output}
        """

