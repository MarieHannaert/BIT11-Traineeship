# snakemake ILLUMINA
I will make a snakemake pipeline from my bash script **/home/genomics/mhannaert/scripts/complete_illuminapipeline.sh**

## setting up the snakemake enviroment
The structure I need in the enviroment: 
````
snakemake/
├─ Illuminapipeline/
|  ├─ .snakemake
│  ├─ data/
|  |  ├─sampels/
|  ├─ envs
|  ├─ snakefile
│  ├─ config.yaml
│  ├─ README
│  ├─ logs
````
I made this: **/home/genomics/mhannaert/snakemake**

## snakefile 
### fastqc
I will follow the example of the tutorials I followed and the exmple that steve shared with me
To start "easy" I will just enter all the steps in rules, and so make the backbone of my snake file 

The first I tried is the rule for fastqc: 
````
rule fastqc: 
    input: 
        get_fastqc_input_fastqs
    output: 
        directory(fastqc/)
    params: 
        extra: "-t 32"
    log:
    shell:
        "fastqc {params.extra} {input} --extract -o {output}"
````
I don't really know what to fill in in the log part, so I will ask my supervisor
### multiqc
because multiqc is a conda env I needed to export this: 
````
conda activate multiqc
conda env export > multiqc.yml
conda deactivate
````
I added this file to **/home/genomics/mhannaert/snakemake/Illuminapipeline/envs**
I added the following part to the snakefile: 
````
rule multiqc: 
    input: 
        "fastqc/"
    output: 
        directory(multiqc/)
    log: 

    conda:
        "envs/multiqc.yml"
    shell:
        multiqc {input}
````

