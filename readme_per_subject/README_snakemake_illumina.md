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
### continue to adding rules to snakefile 
I asked my supervisor for the log part and to take a look at what I did to make sure I'm on the right track. 

An other question I have is why use directory() and on an other place not? 

What with the part of the script between the "real" steps? 

what with the "rule all" part, I don't realy understand that one. 

params do I need to specify this or when do I hard code this?

for exporting my conda env I use commands like this: 
````
 conda activate skani | conda env export > skani.yml | conda deactivate
````

I added the following parts of code: 
````
configfile: "config.yaml"

def get_fastqc_input_fastqs(wildcards):
    return config["samples"][wildcards.sample]

rule fastqc: 
    input: 
        get_fastqc_input_fastqs
    output: 
        directory(results/00_fastqc/)
    params: 
        extra: "-t 32"
    log:
        "logs/fastqc.log"
    shell:
        "fastqc {params.extra} {input} --extract -o {output} 2>> {log}"

rule multiqc: 
    input: 
        "results/00_fastqc/"
    output: 
        directory(results/01_multiqc/)
    log: 
        "logs/multiqc.log"
    conda:
        "envs/multiqc.yml"
    shell:
        "multiqc {input} 2>> {log}"
        "rm -rd {input} 2>> {log}"
        "mv multiqc_report.html {output}"

rule Kraken2:
    input: 
        get_fastqc_input_fastqs
    output: 
       "results/02_kraken2/{sample}_kraken2.report"
    params:
        extra: "--threads 16" 
    log: 
        "logs/Kraken2.log"
    shell:
        kraken2 --gzip-compressed {input} --db /var/db/kraken2/Standard --report {output} {params.extra} --quick --memory-mapping 2>> {log}

rule Krona:
    input: 
       "results/02_kraken2/{sample}_kraken2.report"
    output: 
       "results/03_krona/{sample}_krona.html" 
    params:
        extra: "-t 5 -m 3"
    log: 
        "logs/Krona.log"
    conda:
        "envs/krona.yml"
    shell:
        "ktImportTaxonomy {params.extra} -o {output} {input} 2>> {log}"
        "rm {input} 2>> {log}"

rule fastp:
    input: 
        first:"$g"_1.fq.gz
        second:"$g"_2.fq.gz
    output: 
        first: "results/04_fastp/{sample}_1.fq.gz"
        second: "results/04_fastp/{sample}_2.fq.gz"
        html: "results/04_fastp/{sample}_fastp.html"
        json: "results/04_fastp/{sample}_fastp.json"
    params:
        extra: "-w 32"
    log: 
        "logs/fastp.log"
    shell:
        "fastp {params.extra} -i {input.first} -I {input.second} -o {output.first} -O {output.second} -h {output.html} -j {output.json} --detect_adapter_for_pe 2>> {log}

rule shovill:
    input: 
        first: "results/04_fastp/{sample}_1.fq.gz"
        second: "results/04_fastp/{sample}_2.fq.gz"
    output: 
        "results/05_shovill"
    params:
        extra: "--cpus 16 --ram 16 --minlen 500 --trim"
    log: 
        "logs/shovill.log"
    conda:
        "envs/shovill.yml"
    shell:
        shovill --R1 {input.first} --R2 {input.second} {params.extra} -outdir {output} 

rule assemblies:
    input: 
        copie:"results/05_shovill/"
        remove: "results/04_fastp/{sample}.fq.gz"
    output: 
        "results/assemblies/"$d".fna"
    shell:
        "for d in $(ls -d {input.copie}); do cp "$d"/contigs.fa {output}; done"
        "rm {input.remove}"

rule skANI:
    input: 
        "results/assemblies/{sample}.fna"
    output: 
        "results/06_skani/skani_results_file.txt"
    params:
        extra: "-t 24 -n 1"
    log: 
       "logs/skani.log" 
    conda:
        "envs/skani.yml"
    shell:
        skani search {input} -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o {output} {params.extra} 2>> {log}

rule Quast:
    input: 
       "results/assemblies/{sample}.fna" 
    output: 
        directory("results/07_quast/")
    conda:
        "envs/quast.yml"
    shell:
        "for f in {input}; do quast.py "$f" -o {output}"$f";done" 

rule quast_summarie:
    input: 
       "results/assemblies/{sample}.fna" 
    output: 
        "results/07_quast/quast_summary_table.txt"
    shell:
        "touch {output}"
        "echo -e "Assembly\tcontigs (>= 0 bp)\tcontigs (>= 1000 bp)\tcontigs (>= 5000 bp)\tcontigs (>= 10000 bp)\tcontigs (>= 25000 bp)\tcontigs (>= 50000 bp)\tTotal length (>= 0 bp)\tTotal length (>= 1000 bp)\tTotal length (>= 5000 bp)\tTotal length (>= 10000 bp)\tTotal length (>= 25000 bp)\tTotal length (>= 50000 bp)\tcontigs\tLargest contig\tTotal length\tGC (%)\tN50\tN90\tauN\tL50\tL90\tN's per 100 kbp" >> {output}"
        "counter=1
        for file in $(find -type f -name "transposed_report.tsv"); do
            # Show progress
            echo "Processing file: $counter"
            # Add the content of each file to the summary table (excluding the header)
            tail -n +2 "$file" >> {output}
            # Increment the counter
            counter=$((counter+1))
        done"

rule excel_and_beeswarm: 
    input:
        excel: "skani_quast_to_xlsx.py"
        beeswarm: "beeswarm_vis_assemblies.R"
        directory: ""
        quast:"results/07_quast/quast_summary_table.txt"
    shell:
        "{input.excel} {input.directory}"
        "{input.beeswarm} {input.directory}{input.quast}"

rule Busco:
    input: 
        "results/assemblies/{sample}.fna" 
    output: 
        "results/08_busco/{sample}"
    params:
        extra: "-m genome --auto-lineage-prok -c 32"  
    conda:
        "envs/busco.yml"
    shell:
        "for sample in $(ls {input} | awk 'BEGIN{FS=".fna"}{print $1}'); do busco -i "$sample".fna -o {output} {params.extra} ; done"
rule Busco:
    input: 
        sample:"results/08_busco/{sample}" 
        script: "generate_plot.py"
    output: 
        directory("results/busco_summaries")
    conda:
        "envs/busco.yml"
    shell:
        "cp {input.sample}/*/*/short_summary.specific.burkholderiales_odb10.*.txt {output}"
        "cd {output}"
        "for i in $(seq 1 15 $(ls -1 | wc -l)); do
            echo "Verwerking van bestanden $i tot $((i+14))"
            mkdir -p part_"$i-$((i+14))"
            ls -1 | tail -n +$i | head -15 | while read file; do
                echo "Verwerking van bestand: $file"
                mv "$file" part_"$i-$((i+14))"
            done
            {input.script} -wd part_"$i-$((i+14))"
        done"
````
### improve my existing code 

I will check my code with the following command in **/home/genomics/mhannaert/snakemake/Illuminapipeline**: 
````
snakemake -np 
````
I got the following errors: 
````
SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 9:
invalid decimal literal (snakefile, line 9) 
-> solution: "" around the directory in output

SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 21:
invalid decimal literal (snakefile, line 21)
-> same as above

SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 72:
unterminated string literal (detected at line 73 (snakefile, line 72)
-> didn't close "" 

SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 129:
unexpected character after line continuation character (snakefile, line 129)
-> I rewright this rul to:
rule quast_summarie:
    input: 
       "results/assemblies/{sample}.fna" 
    output: 
        "results/07_quast/quast_summary_table.txt"
    params:
        header:"Assembly\tcontigs (>= 0 bp)\tcontigs (>= 1000 bp)\tcontigs (>= 5000 bp)\tcontigs (>= 10000 bp)\tcontigs (>= 25000 bp)\tcontigs (>= 50000 bp)\tTotal length (>= 0 bp)\tTotal length (>= 1000 bp)\tTotal length (>= 5000 bp)\tTotal length (>= 10000 bp)\tTotal length (>= 25000 bp)\tTotal length (>= 50000 bp)\tcontigs\tLargest contig\tTotal length\tGC (%)\tN50\tN90\tauN\tL50\tL90\tN's per 100 kbp"
    shell:
        """
        # Create the output file and add the header
        echo -e "{header}" >> {output.summary_table}

        # Initialize a counter for the number of files processed
        counter=0

        # Find and process all transposed_report.tsv files
        for file in $(find -type f -name "transposed_report.tsv"); do
            # Add the content of each file to the summary table (excluding the header)
            tail -n +2 "$file" >> {output.summary_table}
            # Increment the counter
            counter=$((counter+1))
        done
    """

SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 178:
unterminated string literal (detected at line 181 (snakefile, line 178)
-> Also this I rewright the shell part:
    shell:
        """
        cp {input.sample}/*/*/short_summary.specific.burkholderiales_odb10.*.txt {output}
        cd {output}
        for i in $(seq 1 15 $(ls -1 | wc -l)); do
            echo "Processing files $i to $((i+14))"
            mkdir -p part_"$i-$((i+14))"
            ls -1 | tail -n +$i | head -15 | while read file; do
                echo "Processing file: $file"
                mv "$file" part_"$i-$((i+14))"
            done
            {input.script} -wd part_"$i-$((i+14))"
        done
        """
SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 12:
invalid syntax (snakefile, line 12)
-> it must be a "=" ipv ":"
I made this error on multiple places, so I changed them all 

SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 42:
invalid syntax. Perhaps you forgot a comma? (snakefile, line 42)
-> I forgot the "" around the command in the shell part 

SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 61:
invalid syntax. Perhaps you forgot a comma? (snakefile, line 61)
-> forgot the "" around 

SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 64:
invalid syntax. Perhaps you forgot a comma? (snakefile, line 64)
-> after each variable I need to paste a "," when I have multiple
-> I check and changed this over the whole file 

SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 95:
invalid syntax (snakefile, line 95)
-> changed the "$b" to {sample}

SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 97:
Command must be given as string after the shell keyword. (snakefile, line 97)
-> the complete shell block needs to be a string, so I placed everything between """ """

SyntaxError in file /home/genomics/mhannaert/snakemake/Illuminapipeline/snakefile, line 123:
invalid syntax (snakefile, line 123)
-> same problem as above, so I went checking everywhere and changed everything to """ """

WorkflowError:
Config file must be given as JSON or YAML with keys at top level.
-> made my config.yaml file

````
## config file 
I made the config file for four samples, when I looked at the samples and how I need them in my snakemake I can to this structure: 
```
samples:
  samples_1:
    sample01_1: data/samples/070_001_240321_001_0355_099_01_4691_1.fq.gz
    sample02_1: data/samples/070_001_240321_001_0356_099_01_4691_1.fq.gz   
  samples_2:
    sample01_2: data/samples/070_001_240321_001_0355_099_01_4691_2.fq.gz
    sample02_2: data/samples/070_001_240321_001_0356_099_01_4691_2.fq.gz
```
So them I have to change this in my snakefile in the beginning: 
````
def get_fastqc_input_fastqs(wildcards):
    """
    Returns the input FASTQ file(s) for the given sample.

    Args:
        wildcards (object): contains the sample name

    Returns:
        list: FASTQ file(s) for the sample
    """
    sample_group, sample_id = wildcards.sample.split("_")
    return config["samples"][sample_group][sample_id]
````
Now I have to use this in my snake file when I need this input 
I changed the following in- and outputs where needed. 

### checking again after changes 
performing the command "snakemake -np" in the folder **/home/genomics/mhannaert/snakemake/Illuminapipeline**
````
SyntaxError:
Not all output, log and benchmark files of rule Kraken2 contain the same wildcards. This is crucial though, in order to avoid that two or more jobs write to the same file.`
-> I went looking but didn't saw it, so asked blackbox AI

backbox AI changed something that wasn't correct so I needed to change this back 

So I went checking everything 
````

I added the following part: 
````
rule all:
    input:
        expand("results/00_fastqc/", sample=config["samples"]),
        expand("results/02_kraken2/{sample}_kraken2.report", sample=config["samples"]),
        expand("results/03_krona/{sample}_krona.html", sample=config["samples"]),
        expand("results/04_fastp/{sample}_1.fq.gz", sample=config["samples"]),
        expand("results/04_fastp/{sample}_2.fq.gz", sample=config["samples"]),
        expand("results/05_shovill/{sample}/contigs.fa", sample=config["samples"]),
        expand("results/assemblies/{sample}.fna", sample=config["samples"]),
        "results/06_skani/skani_results_file.txt",
        "results/07_quast/quast_summary_table.txt",
        "results/busco_summaries",
        expand("results/08_busco/{sample}/", sample=config["samples"])
````
now checking my code again with the snakemake -np command: 
````
SyntaxError:
Not all output, log and benchmark files of rule fastp contain the same wildcards. This is crucial though, in order to avoid that two or more jobs write to the same file.
````
I got this error but I can get it fixed....
I asked my supervisor for the bug he's going to take a look at everything. 
So I'm going to wait on this feedback before working further on the snakemake. 

## working further 
On advise of my supervisor I installed the snakemake language extension and the snakefmt extension in VSC, this will prob help with my syntax. 

maybe I need to add a shebang line of snakemake 

I talked with my supervisor about it and he gave me some new information about the config file and the samples:
````
IDS, = glob_wildcards("{id}_R1.fastq.gz")
 
rule all:
  input:
    expand(["taxonomy/{id}.krona.html"], id=IDS),
    "iqtree.log",
    "results/",
    "amr_output.tab",
    "heatmap_output.html"
# Cleaning up fastq files    
rule fastp:
	input:
		["{id}_R1.fastq.gz", "{id}_R2.fastq.gz"]
	output:
		["fastp/{id}_R1.fastq.gz.fastp", "fastp/{id}_R2.fastq.gz.fastp"]
	message:
		"Filtering fastQ files by trimming low quality reads using fastp"
	shell:
		"fastp -i {input[0]} -I {input[1]} -o {output[0]} -O {output[1]}"


The pattern {id}_R1.fastq.gz specifies that the function should look for files with the .fastq.gz extension and a prefix that matches the pattern {id}_R1. The {id} part of the pattern is a wildcard that can match any string of characters.
The glob_wildcards function returns a list of all the matching file prefixes, which are stored in the variable IDS.
So, if you have the following files in your directory:
sample1_R1.fastq.gz
sample2_R1.fastq.gz
sample3_R1.fastq.gz
The glob_wildcards function will return the following list:
IDS = ['sample1', 'sample2', 'sample3']
This list can then be used in a Snakemake rule to process each file individually. For example, you might use the IDS list to create a rule that maps each read file to a reference genome, like this:
````
Also I'm reading the documentation again 
while doing this all and having all this information, I will update my script, when I'm done you can find the changes I made in my github under the commit with the message of "improving snakefile"

It wasn't succesfull, It looks like I have more erros then when I started with this

## fixing the snakemake 
````
InputFunctionException in rule fastqc in file /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile, line 23:
Error:
  AttributeError: 'Wildcards' object has no attribute 'sample'
Wildcards:

Traceback:
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile", line 20, in get_sample_input_fastqs (rule fastqc, line 32, /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile)
````
This is the error where I start with today, I think I will use the more python way of defining my samples. 

I did it now on the following way: 
````
# Define list of conditions
IDS, = glob_wildcards("{id}_1.fq.gz")
CONDITIONS = ["1", "2"]

# Define directories
REFDIR = "/home/genomics/mhannaert/snakemake/Illuminapipeline"
SAMDIR = REFDIR + "/data/samples/"
RESDIR = "/results"
DIRS = ["00_fastqc/","01_multiqc/","02_kraken2/","03_krona/"]

rule all:
    input: 
        expand("results/{dirs}", dirs= DIRS)

# Rule to perform FastQC analysis
rule fastqc:
    input:
        expand(SAMDIR+"{id}_{con}.fq.gz", id= IDS, con=CONDITIONS)
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
````
And this gave me a new error, what's give me hope
````
Building DAG of jobs...
MissingInputException in rule fastqc in file /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile, line 16:
Missing input files for rule fastqc:
    output: results/00_fastqc
    affected files:
        /home/genomics/mhannaert/snakemake/Illuminapipeline/data/samples/data/sampels/070_001_240321_001_0356_099_01_4691_2.fq.gz
        /home/genomics/mhannaert/snakemake/Illuminapipeline/data/samples/data/sampels/070_001_240321_001_0356_099_01_4691_1.fq.gz
        /home/genomics/mhannaert/snakemake/Illuminapipeline/data/samples/data/sampels/070_001_240321_001_0355_099_01_4691_2.fq.gz
        /home/genomics/mhannaert/snakemake/Illuminapipeline/data/samples/data/sampels/070_001_240321_001_0355_099_01_4691_1.fq.gz
````
I can see in the error that a part of the path is double "/data/samples" so there will be an error some where with the path. 
I will in the input part change the sam dir to refdir because that has not that specific part in it. It solved it, I got the following output:
````
Building DAG of jobs...
Job stats:
job        count
-------  -------
all            1
fastqc         1
multiqc        1
total          3

Execute 1 jobs...

[Thu May 16 14:38:59 2024]
localrule fastqc:
    input: /home/genomics/mhannaert/snakemake/Illuminapipeline/data/sampels/070_001_240321_001_0355_099_01_4691_1.fq.gz, /home/genomics/mhannaert/snakemake/Illuminapipeline/data/sampels/070_001_240321_001_0355_099_01_4691_2.fq.gz, /home/genomics/mhannaert/snakemake/Illuminapipeline/data/sampels/070_001_240321_001_0356_099_01_4691_1.fq.gz, /home/genomics/mhannaert/snakemake/Illuminapipeline/data/sampels/070_001_240321_001_0356_099_01_4691_2.fq.gz
    output: results/00_fastqc
    log: logs/fastqc
    jobid: 1
    reason: Missing output files: results/00_fastqc
    resources: tmpdir=<TBD>

Execute 1 jobs...

[Thu May 16 14:38:59 2024]
localrule multiqc:
    input: results/00_fastqc
    output: results/01_multiqc
    log: logs/multiqc.log
    jobid: 2
    reason: Missing output files: results/01_multiqc; Input files updated by another job: results/00_fastqc
    resources: tmpdir=<TBD>

Execute 1 jobs...

[Thu May 16 14:38:59 2024]
localrule all:
    input: results/00_fastqc, results/01_multiqc
    jobid: 0
    reason: Input files updated by another job: results/01_multiqc, results/00_fastqc
    resources: tmpdir=<TBD>

Job stats:
job        count
-------  -------
all            1
fastqc         1
multiqc        1
total          3

Reasons:
    (check individual jobs above for details)
    input files updated by another job:
        all, multiqc
    missing output files:
        fastqc, multiqc

This was a dry-run (flag -n). The order of jobs does not reflect the order of execution.
````
SO still some small issues, I will fix themm now. It looks like I need to realy specify each output FILE, the most errors come with the use of directories. 

I execute the snakemake I need to use the following command:
 ````
 snakemake --use-conda -j 4
 ````
 When I do this the outut I now got is: 
 ````
 Building DAG of jobs...
Your conda installation is not configured to use strict channel priorities. This is however crucial for having robust and correct environments (for details, see https://conda-forge.org/docs/user/tipsandtricks.html). Please consider to configure strict priorities by executing 'conda config --set channel_priority strict'.
Creating conda environment envs/multiqc.yml...
Downloading and installing remote packages.
Environment for /home/genomics/mhannaert/snakemake/Illuminapipeline/envs/multiqc.yml created (location: .snakemake/conda/f603d5f182bf6b4214b829cdb04e8efc_)
Retrieving input from storage.
Using shell: /usr/bin/bash
Provided cores: 4
Rules claiming more threads will be scaled down.
Job stats:
job        count
-------  -------
all            1
multiqc        1
total          2

Select jobs to execute...
Execute 1 jobs...

[Thu May 16 15:44:06 2024]
localrule multiqc:
    output: results/01_multiqc, results/01_multiqc/multiqc_report.html
    log: logs/multiqc.log
    jobid: 1
    reason: Missing output files: results/01_multiqc/multiqc_report.html
    resources: tmpdir=/tmp

Activating conda environment: .snakemake/conda/f603d5f182bf6b4214b829cdb04e8efc_
                                                                                                                                                                                        
 Usage: multiqc [OPTIONS] [ANALYSIS DIRECTORY]                                                                                                                                          
                                                                                                                                                                                        
 This is MultiQC v1.21                                                                                                                                                                  
 For more help, run 'multiqc --help' or visit http://multiqc.info                                                                                                                       
╭─ Error ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Missing argument '[ANALYSIS DIRECTORY]'.                                                                                                                                             │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
                                                                                                                                                                                        
[Thu May 16 15:44:07 2024]
Error in rule multiqc:
    jobid: 1
    output: results/01_multiqc, results/01_multiqc/multiqc_report.html
    log: logs/multiqc.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/f603d5f182bf6b4214b829cdb04e8efc_
    shell:
        
        mkdir -p results/01_multiqc
        multiqc  -o results/01_multiqc/ 2>> logs/multiqc.log
        
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Removing output files of failed job multiqc since they might be corrupted:
results/01_multiqc
Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-16T154029.848592.snakemake.log
WorkflowError:
At least one job did not complete successfully.
 ````
 The important part of this output is the following: 
 ````
  shell:
        
        mkdir -p results/01_multiqc
        multiqc  -o results/01_multiqc/ 2>> logs/multiqc.log
 ````
 The input is not correct, so I changed the multiqc part: 
 ````
 rule multiqc:
    output:
        directory("results/01_multiqc/"),
        "results/01_multiqc/multiqc_report.html"
    log:
        "logs/multiqc.log"
    conda:
        "envs/multiqc.yml"
    shell:
        """
        mkdir -p results/01_multiqc
        multiqc results/00_fastqc/ -o results/01_multiqc/ 2>> {log}
        
        """

This gave the following important error: 
│ Invalid value for '[ANALYSIS DIRECTORY]': Path 'results/00_fastqc/' does not exist. 
 ````
 SO maybe I need to make the results folder in the pipeline
 So in the fastqc part I added the line to make the folder. 

 So I got a new error: 
 ````
 Building DAG of jobs...
ChildIOException:
File/directory is a child to another output:
('/home/genomics/mhannaert/snakemake/Illuminapipeline/results', fastqc)
('/home/genomics/mhannaert/snakemake/Illuminapipeline/results/01_multiqc', multiqc)
 ````
 I got now all several times the same error: 
 ````
 Invalid value for '[ANALYSIS DIRECTORY]': Path 'results/00_fastqc/' does not exist.     
 ````
I tried to make as a first rule making the directory, it always by the multiqc part it goes wrong. 
So I will change that  part again

There is a problem:
````
│ Invalid value for '[ANALYSIS DIRECTORY]': Path 'results/00_fastqc/' does not exist.   
````
To fix this error, I removed the multiqc temeary 
So now I'm only testing with the following: 
````
# Define list of conditions
IDS, = glob_wildcards("data/samples/{id}_1.fq.gz")
CONDITIONS = ["1", "2"]

# Define directories
REFDIR = "/home/genomics/mhannaert/snakemake/Illuminapipeline/"
SAMDIR = REFDIR + "/data/samples/"
RESDIR = "/results"
DIRS = ["00_fastqc/"]
#,"01_multiqc/","02_kraken2/","03_krona/"
rule all:
    input: 
        expand("results/00_fastqc/{id}_{con}_fastqc.zip", id=IDS, con=CONDITIONS)
        #, expand("results/00_fastqc/{id}_{con}_fastqc.html",id=IDS, con=CONDITIONS),
        #"results/01_multiqc/multiqc_report.html"

rule Making_results_dir:
    output:
        directory("results/")
    shell:
        """
        mkdir -p {output}
        """

# Rule to perform FastQC analysis
rule fastqc:
    input:
        expand(REFDIR+"data/samples/{id}_{con}.fq.gz", id= IDS, con=CONDITIONS)
    output:
        directory("results/00_fastqc/"),
        expand("results/00_fastqc/{id}_{con}_fastqc.zip", id=IDS, con=CONDITIONS),
        expand("results/00_fastqc/{id}_{con}_fastqc.html",id=IDS, con=CONDITIONS)
    log:
        "logs/fastqc.log"
    params:
        extra="-t 32",

    shell:
        """
        mkdir -p results/00_fastqc
        fastqc {params.extra} {input} --extract -o {output[0]} 2>> {log}
        """
````
I removed also the fastqc part and checked again, the rule for making the results folder is fine, so now I will add a part for making all the folders at once in the results folder. 

To check I will only start with fastqc and multiqc. 
so this is whats in my snakefile at the moment: 
````
# Define list of conditions
IDS, = glob_wildcards("data/samples/{id}_1.fq.gz")
CONDITIONS = ["1", "2"]

# Define directories
REFDIR = "/home/genomics/mhannaert/snakemake/Illuminapipeline/"

rule all:
    input: 
        "results/",
        "results/00_fastqc/",
        "results/01_multiqc"
        #expand("results/00_fastqc/{id}_{con}_fastqc.zip", id=IDS, con=CONDITIONS), 
        #expand("results/00_fastqc/{id}_{con}_fastqc.html",id=IDS, con=CONDITIONS),
        #"results/01_multiqc/multiqc_report.html"

rule Making_results_dir:
    output:
        directory("results/")
    shell:
        """
        mkdir -p {output}
        """
rule Making_output_dirs:
    input:
        "results/"
    output:
        directory("results/00_fastqc/"),
        directory("results/01_multiqc")
    shell:
        """
        mkdir -p {output[0]}
        mkdir -p {output[1]}
        """

````
I changed my Snakefile back. 
to a previous state: 
````
# Define list of conditions
IDS, = glob_wildcards("data/samples/{id}_1.fq.gz")
CONDITIONS = ["1", "2"]

# Define directories
REFDIR = "/home/genomics/mhannaert/snakemake/Illuminapipeline/"

rule all:
    input: 
        "results/00_fastqc/", "results/01_multiqc/",
        expand("results/00_fastqc/{id}_{con}_fastqc.zip", id=IDS, con=CONDITIONS), 
        expand("results/00_fastqc/{id}_{con}_fastqc.html",id=IDS, con=CONDITIONS),
        "results/01_multiqc/multiqc_report.html"

rule Making_results_dir:
    output:
        directory("results/")
    shell:
        """
        mkdir -p {output}
        cd {output}
        """
rule Making_output_dirs:
    output:
        directory("00_fastqc/"),
        directory("01_multiqc")
    shell:
        """
        mkdir -p {output[0]}
        mkdir -p {output[1]}
        """
# Rule to perform FastQC analysis
rule fastqc:
    output:
        directory("results/00_fastqc/"),
        expand("results/00_fastqc/{id}_{con}_fastqc.zip", id=IDS, con=CONDITIONS),
        expand("results/00_fastqc/{id}_{con}_fastqc.html",id=IDS, con=CONDITIONS)
    log:
        "logs/fastqc.log"
    params:
        extra="-t 32"

    shell:
        """
        mkdir -p results/00_fastqc/
        fastqc {params.extra} data/samples/ --extract -o {output[0]} 2>> {log}
        """   
rule multiqc:
    output:
        directory("results/01_multiqc/"),
        "results/01_multiqc/multiqc_report.html"
    log:
        "logs/multiqc.log"
    conda:
        "envs/multiqc.yml"
    shell:
        """
        mkdir -p results/01_multiqc/
        multiqc results/00_fastqc/ -o results/01_multiqc/ 2>> {log}
        """
````
With this code I got the following error: 
````
Building DAG of jobs...
Your conda installation is not configured to use strict channel priorities. This is however crucial for having robust and correct environments (for details, see https://conda-forge.org/docs/user/tipsandtricks.html). Please consider to configure strict priorities by executing 'conda config --set channel_priority strict'.
Retrieving input from storage.
Using shell: /usr/bin/bash
Provided cores: 4
Rules claiming more threads will be scaled down.
Job stats:
job        count
-------  -------
all            1
multiqc        1
total          2

Select jobs to execute...
Execute 1 jobs...

[Thu May 16 17:13:23 2024]
localrule multiqc:
    output: results/01_multiqc, results/01_multiqc/multiqc_report.html
    log: logs/multiqc.log
    jobid: 2
    reason: Missing output files: results/01_multiqc/multiqc_report.html, results/01_multiqc
    resources: tmpdir=/tmp

Activating conda environment: .snakemake/conda/f603d5f182bf6b4214b829cdb04e8efc_
Waiting at most 5 seconds for missing files.
MissingOutputException in rule multiqc in file /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile, line 48:
Job 2  completed successfully, but some output files are missing. Missing files after 5 seconds. This might be due to filesystem latency. If that is the case, consider to increase the wait time with --latency-wait:
results/01_multiqc/multiqc_report.html
Removing output files of failed job multiqc since they might be corrupted:
results/01_multiqc
Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-16T171321.502182.snakemake.log
WorkflowError:
At least one job did not complete successfully.
````
I removed "results/01_multiqc/multiqc_report.html" out of the rule all. And now I don't get that error anymore but still don't get any output, the folders are made, but the output is not made, This is the output I get in the terminal: 
````
Building DAG of jobs...
Your conda installation is not configured to use strict channel priorities. This is however crucial for having robust and correct environments (for details, see https://conda-forge.org/docs/user/tipsandtricks.html). Please consider to configure strict priorities by executing 'conda config --set channel_priority strict'.
Retrieving input from storage.
Using shell: /usr/bin/bash
Provided cores: 4
Rules claiming more threads will be scaled down.
Job stats:
job        count
-------  -------
all            1
multiqc        1
total          2

Select jobs to execute...
Execute 1 jobs...

[Thu May 16 17:20:08 2024]
localrule multiqc:
    output: results/01_multiqc
    log: logs/multiqc.log
    jobid: 2
    reason: Missing output files: results/01_multiqc
    resources: tmpdir=/tmp

Activating conda environment: .snakemake/conda/f603d5f182bf6b4214b829cdb04e8efc_
[Thu May 16 17:20:09 2024]
Finished job 2.
1 of 2 steps (50%) done
Select jobs to execute...
Execute 1 jobs...

[Thu May 16 17:20:09 2024]
localrule all:
    input: results/00_fastqc, results/01_multiqc
    jobid: 0
    reason: Input files updated by another job: results/01_multiqc
    resources: tmpdir=/tmp

[Thu May 16 17:20:09 2024]
Finished job 0.
2 of 2 steps (100%) done
Complete log: .snakemake/log/2024-05-16T172006.817454.snakemake.log
````
I removed the output and input from the fastqc and the multiqc 
and tried again. 
This was really not a succes. 
Because of the folders that exist it didn't do anything. 
I changed the following line: fastqc -t 32 data/samples/*.gz --extract -o {output[0]} 2>> {log}

but still don't get any output inmy directories, in the terminal I got the following output: 
````
Building DAG of jobs...
Your conda installation is not configured to use strict channel priorities. This is however crucial for having robust and correct environments (for details, see https://conda-forge.org/docs/user/tipsandtricks.html). Please consider to configure strict priorities by executing 'conda config --set channel_priority strict'.
Retrieving input from storage.
Using shell: /usr/bin/bash
Provided cores: 4
Rules claiming more threads will be scaled down.
Job stats:
job       count
------  -------
all           1
fastqc        1
total         2

Select jobs to execute...
Execute 1 jobs...

[Thu May 16 17:35:29 2024]
localrule fastqc:
    output: results/00_fastqc
    log: logs/fastqc.log
    jobid: 1
    reason: Code has changed since last execution; Params have changed since last execution
    resources: tmpdir=/tmp

[Thu May 16 17:35:29 2024]
Finished job 1.
1 of 2 steps (50%) done
Select jobs to execute...
Execute 1 jobs...

[Thu May 16 17:35:29 2024]
localrule all:
    input: results/00_fastqc, results/01_multiqc
    jobid: 0
    reason: Input files updated by another job: results/00_fastqc
    resources: tmpdir=/tmp

[Thu May 16 17:35:29 2024]
Finished job 0.
2 of 2 steps (100%) done
Complete log: .snakemake/log/2024-05-16T173527.062609.snakemake.log
````
## Checking again information about synthax and looking for a solution 
I found this article https://academic.oup.com/bioinformatics/article/28/19/2520/290322
I saw this part of code: 
````
SAMPLES =  "  100 101 102 103  "  .split()

REF =  "  hg19.fa  "

rule  all:

 input: "{sample}.coverage.pdf".format(sample = sample)

    for sample in SAMPLES

rule   fastq_to_sai:

  input: ref = REF, reads = "{sample}.{group}.fastq"

  output: temp("{sample}.{group}.sai")

  shell: "bwa aln {input.ref} {input.reads} > {output}"

````
maybe this is a solution to my problem, the for loop on top for each sample in the directory
I misread the code, the for loop is under the rule all, not above 

An other thing I tought I could check out is the difference in use of "shell" or "run"
-> "shell:" is for not python code, "run:" is for python code 

An other thing that I needed to know is to let rule wait, to another rule to finish because it's needed as input 
-> Snakemake determines the execution order of the rules according to the inputs and outputs of the rules. If you define a directory, and not files, as output of a rule, it can indeed be confusing for snakemake. The documentation (https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#directories-as-outputs) states:

Always consider if you can’t formulate your workflow using normal files before resorting to using directory()

A way to be sure your first rules runs to the end before executing the second rule is to use the touch() function (https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#flag-files)

this is interesting information, because I use the directories it doesn't wait, so I will change as mutch as possible to files. 

I changed my code to: 
````
import os 

# Define list of conditions
#IDS, = glob_wildcards("data/samples/{id}_1.fq.gz")
CONDITIONS = ["1", "2"]

# Define directories
REFDIR = "/home/genomics/mhannaert/snakemake/Illuminapipeline/"
sample_dir = REFDIR+"data/samples/"
os.chdir(REFDIR)

print(os.getcwd())

for files in os.listdir(sample_dir):
        sample = files.split("_")[0]
    
rule all:
    input: 
        "results/00_fastqc/", "results/01_multiqc/",
        expand("results/00_fastqc/{sample}_{con}_fastqc.zip", sample=sample, con=CONDITIONS), 
        expand("results/00_fastqc/{sample}_{con}_fastqc.html",sample=sample, con=CONDITIONS),
        "results/01_multiqc/multiqc_report.html"

rule Making_results_dir:
    output:
        directory("results/"),
        "results/done.txt"
    shell:
        """
        mkdir -p {output}
        touch done.txt > {output}
        """

# Rule to perform FastQC analysis
rule fastqc:
    input:
        expand('data/samples/{sample}_{con}.fq.gz', sample=sample, con=CONDITIONS),
        "results/done.txt"
    output:
        directory("results/00_fastqc/"),
        expand("results/00_fastqc/{sample}_{con}_fastqc.zip", sample=sample, con=CONDITIONS), 
        expand("results/00_fastqc/{sample}_{con}_fastqc.html",sample=sample, con=CONDITIONS)
    log:
        "logs/fastqc.log"
    shell:
        """
        mkdir -p results/00_fastqc/
        fastqc -t 32 {input[0]} --extract -o {output[0]} 2>> {log}
        """   
rule multiqc:
    input:
        expand("results/00_fastqc/{sample}_{con}_fastqc.zip", sample=sample, con=CONDITIONS), 
        expand("results/00_fastqc/{sample}_{con}_fastqc.html",sample=sample, con=CONDITIONS),
        "results/00_fastqc/"
    output:
        directory("results/01_multiqc/"),
        "results/01_multiqc/multiqc_report.html"
    log:
        "logs/multiqc.log"
    conda:
        "envs/multiqc.yml"
    shell:
        """
        mkdir -p results/01_multiqc/
        multiqc {input[2]} -o {output[0]} 2>> {log}
        """
````
But I got the following error: 
````
/home/genomics/mhannaert/snakemake/Illuminapipeline
Traceback (most recent call last):
  File "/opt/miniforge3/envs/snakemake/lib/python3.12/site-packages/snakemake/cli.py", line 1886, in args_to_api
    dag_api = workflow_api.dag(
              ^^^^^^^^^^^^^^^^^
  File "/opt/miniforge3/envs/snakemake/lib/python3.12/site-packages/snakemake/api.py", line 326, in dag
    return DAGApi(
           ^^^^^^^
  File "<string>", line 6, in __init__
  File "/opt/miniforge3/envs/snakemake/lib/python3.12/site-packages/snakemake/api.py", line 436, in __post_init__
    self.workflow_api._workflow.dag_settings = self.dag_settings
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/miniforge3/envs/snakemake/lib/python3.12/site-packages/snakemake/api.py", line 383, in _workflow
    workflow.include(
  File "/opt/miniforge3/envs/snakemake/lib/python3.12/site-packages/snakemake/workflow.py", line 1374, in include
    exec(compile(code, snakefile.get_path_or_uri(), "exec"), self.globals)
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile", line 14, in <module>
    for files in os.listdir(sample_dir):
                 ^^^^^^^^^^^^^^^^^^^^^^^^
FileNotFoundError: [Errno 2] No such file or directory: '/home/genomics/mhannaert/snakemake/Illuminapipeline/data/samples/'
````
This is a strange error because I can see that it exist

-> I made some typos, that's why it wasn't working
after fixing these I got the following output: 
````
/home/genomics/mhannaert/snakemake/Illuminapipeline
Building DAG of jobs...
MissingInputException in rule fastqc in file /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile, line 35:
Missing input files for rule fastqc:
    output: results/00_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_2.fq.gz_1_fastqc.zip, results/00_fastqc/070_001_240321_001_0356_099_01_4691_2.fq.gz_2_fastqc.zip, results/00_fastqc/070_001_240321_001_0356_099_01_4691_2.fq.gz_1_fastqc.html, results/00_fastqc/070_001_240321_001_0356_099_01_4691_2.fq.gz_2_fastqc.html
    affected files:
        data/sampels/070_001_240321_001_0356_099_01_4691_2.fq.gz_2.fq.gz
        data/sampels/070_001_240321_001_0356_099_01_4691_2.fq.gz_1.fq.gz
````
To extract the sample names I made the fopllowing part of code: 
````
print(os.getcwd())
sample_names = []
sample_list = os.listdir(sample_dir)
for i in range(len(sample_list)):
    sample = sample_list[i]
    if sample.endswith("_1.fq.gz"):
        samples = sample.split("_1.fq")[0]
        sample_names.append(samples)
        print(sample_names)
````
I think this will be easier to work with in the snakemake, oke this part works:
````
/home/genomics/mhannaert/snakemake/Illuminapipeline
['070_001_240321_001_0355_099_01_4691']
['070_001_240321_001_0355_099_01_4691', '070_001_240321_001_0356_099_01_4691']
````
So now it's making thnext parts work, because I also got the following error:
````
MissingInputException in rule all in file /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile, line 21:
Missing input files for rule all:
    affected files:
        results/00_fastqc/070_001_240321_001_0356_099_01_4691_2_fastqc.zip
        results/00_fastqc/070_001_240321_001_0356_099_01_4691_1_fastqc.zip
        results/00_fastqc/070_001_240321_001_0355_099_01_4691_2_fastqc.zip
        results/00_fastqc/070_001_240321_001_0355_099_01_4691_1_fastqc.zip
        results/01_multiqc/multiqc_report.html
        results/00_fastqc/070_001_240321_001_0356_099_01_4691_2_fastqc.html
        results/00_fastqc/070_001_240321_001_0355_099_01_4691_2_fastqc.html
        results/00_fastqc/070_001_240321_001_0356_099_01_4691_1_fastqc.html
        results/00_fastqc/070_001_240321_001_0355_099_01_4691_1_fastqc.html
````
I think the names of the files are already correct so it's only making the input correct and checking that the steps will follow eachother nicely

Oke notthing really worked, so I went back to the documentation, because I think the problem is the rule all in the snakemake. When I see in the documentation that they are making a snakemake wokrflow they will first define all theire rules and then the "rule all". so I will also now try this way of working. 

````
import os
# Define list of conditions
#IDS, = glob_wildcards("data/samples/{id}_1.fq.gz")
CONDITIONS = ["1", "2"]

# Define directories
REFDIR = "/home/genomics/mhannaert/snakemake/Illuminapipeline/"
sample_dir = REFDIR+"data/sampels/"
os.chdir(REFDIR)

print(os.getcwd())
sample_names = []
sample_list = os.listdir(sample_dir)
for i in range(len(sample_list)):
    sample = sample_list[i]
    if sample.endswith("_1.fq.gz"):
        samples = sample.split("_1.fq")[0]
        sample_names.append(samples)
        print(sample_names)


rule Making_results_dir:
    output:
        directory("results/"),
        "results/done.txt"
    shell:
        """
        mkdir -p {output[0]}
        echo done > {output[1]}
        """

rule fastqc: 
    input:
        sample_dir+sample_names+"_"+CONDITIONS+".fq.gz"
    output:
        directory("results/00_fastqc/")
    params:
        extra="-t 32"
    log:
        "logs/fastqc.log"
    shell:
        """
        fastqc {params.extra} {input} --extract -o {output} 2>> {log}
        """
````
I got the following error:
````
/home/genomics/mhannaert/snakemake/Illuminapipeline
['070_001_240321_001_0355_099_01_4691']
['070_001_240321_001_0355_099_01_4691', '070_001_240321_001_0356_099_01_4691']
Traceback (most recent call last):
  File "/opt/miniforge3/envs/snakemake/lib/python3.12/site-packages/snakemake/cli.py", line 1886, in args_to_api
    dag_api = workflow_api.dag(
              ^^^^^^^^^^^^^^^^^
  File "/opt/miniforge3/envs/snakemake/lib/python3.12/site-packages/snakemake/api.py", line 326, in dag
    return DAGApi(
           ^^^^^^^
  File "<string>", line 6, in __init__
  File "/opt/miniforge3/envs/snakemake/lib/python3.12/site-packages/snakemake/api.py", line 436, in __post_init__
    self.workflow_api._workflow.dag_settings = self.dag_settings
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/miniforge3/envs/snakemake/lib/python3.12/site-packages/snakemake/api.py", line 383, in _workflow
    workflow.include(
  File "/opt/miniforge3/envs/snakemake/lib/python3.12/site-packages/snakemake/workflow.py", line 1374, in include
    exec(compile(code, snakefile.get_path_or_uri(), "exec"), self.globals)
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile", line 48, in <module>
TypeError: can only concatenate str (not "list") to str
````
## THE SOLUTION TO MY BIG PROBLEM
OKAY, AFTER LONG SEARCHING:
````
import os

CONDITIONS = ["1", "2"]
DIRS = ["00_fastqc","01_multiqc"]

# Define directories
REFDIR = "/home/genomics/mhannaert/snakemake/Illuminapipeline/"
sample_dir = REFDIR+"data/sampels/"
result_dir = REFDIR+"results/"
os.chdir(REFDIR)

print(os.getcwd())
sample_names = []
sample_list = os.listdir(sample_dir)
for i in range(len(sample_list)):
    sample = sample_list[i]
    if sample.endswith("_1.fq.gz"):
        samples = sample.split("_1.fq")[0]
        sample_names.append(samples)
        print(sample_names)

for dir in DIRS:
    os.mkdir("results/"+dir)

rule all:
    input:
        expand("results/00_fastqc/{names}_{con}_fastqc/", names=sample_names, con = CONDITIONS)


rule fastqc: 
    input:
        "data/sampels/{names}_{con}.fq.gz"
    output:
        result = directory("results/00_fastqc/{names}_{con}_fastqc/")
    log:
        "logs/{names}_{con}.log"
    params:
        extra="-t 32"
    shell:
        """
        fastqc {params.extra} {input} --extract -o results/00_fastqc/ 2>> {log}
        """
````
I now realy understand snakemake
So in a summary: 
So when I look at this code The first thing:
````
import os

CONDITIONS = ["1", "2"]
DIRS = ["00_fastqc","01_multiqc"]

# Define directories
REFDIR = "/home/genomics/mhannaert/snakemake/Illuminapipeline/"
sample_dir = REFDIR+"data/sampels/"
result_dir = REFDIR+"results/"
os.chdir(REFDIR)
print(os.getcwd())

sample_names = []
sample_list = os.listdir(sample_dir)
for i in range(len(sample_list)):
    sample = sample_list[i]
    if sample.endswith("_1.fq.gz"):
        samples = sample.split("_1.fq")[0]
        sample_names.append(samples)
        print(sample_names)

for dir in DIRS:
    os.mkdir("results/"+dir)
````
This part is all preparation, first I make variables of things I will need, then I will already make the file structure I need to put all my results in. So this wasn't the hard part and this was the part that already was correct, but now it's better. 

Okay for the part after that I removed all the extra parts, so that I could check were it went wrong. So I removed the output directory, the log file and the option con and hard coded that part so that I really could check. 

When I deleted this I still got an error. Now this was the moment I found in the documentation "the click" I needed, a rule eg. fastqc is just definging the step for one sample, so the expand that was there in the beginning was not correct, because for fastqc to perform you only need one sample and not a bunch like for a graph or something like that. So you only need to fill in the variables with curly brackets. That's also the reason that I took out the part about making the directory in the rule and placed it above.

Then the place were these variables will be filled in is the "Rule all", here you need to define the variables like "con = CONDITIONS" because here you want all you results to be there and to be checked. So there can be multiple samples. The "rule" is just like defining a step and the "rule all" is for checking for all the samples. This was the part in my head that I missed. 

So when I realised this I changed my code in this way:
````
rule all:
    input:
        expand("results/00_fastqc/{names}_1_fastqc/", names=sample_names)

rule fastqc: 
    input:
        "data/sampels/{names}_1.fq.gz"
    output:
        result = directory("results/00_fastqc/{names}_{con}_fastqc/")
        extra="-t 32"
    shell:
        """
        fastqc {params.extra} {input} --extract 
        """
````
And this worked, so then I went adding parts like the output directory, checked worked, then changing the 1 again to "con" and as last adding the log file. Also because of these variables that needed to be filled in in the log file you need to use the same, so the name of the log file needed also to contain these variables. With than the following part as result:
````
rule all:
    input:
        expand("results/00_fastqc/{names}_{con}_fastqc/", names=sample_names, con = CONDITIONS)


rule fastqc: 
    input:
        "data/sampels/{names}_{con}.fq.gz"
    output:
        result = directory("results/00_fastqc/{names}_{con}_fastqc/")
    log:
        "logs/{names}_{con}.log"
    params:
        extra="-t 32"
    shell:
        """
        fastqc {params.extra} {input} --extract -o results/00_fastqc/ 2>> {log}
        """
````
So now it will as result gave the following output: 
````
/home/genomics/mhannaert/snakemake/Illuminapipeline
['070_001_240321_001_0355_099_01_4691']
['070_001_240321_001_0355_099_01_4691', '070_001_240321_001_0356_099_01_4691']
Building DAG of jobs...
Retrieving input from storage.
Using shell: /usr/bin/bash
Provided cores: 4
Rules claiming more threads will be scaled down.
Job stats:
job       count
------  -------
all           1
fastqc        4
total         5

Select jobs to execute...
Execute 4 jobs...

[Fri May 17 14:43:40 2024]
localrule fastqc:
    input: data/sampels/070_001_240321_001_0356_099_01_4691_1.fq.gz
    output: results/00_fastqc/070_001_240321_001_0356_099_01_4691_1_fastqc
    log: logs/070_001_240321_001_0356_099_01_4691_1.log
    jobid: 3
    reason: Missing output files: results/00_fastqc/070_001_240321_001_0356_099_01_4691_1_fastqc
    wildcards: names=070_001_240321_001_0356_099_01_4691, con=1
    resources: tmpdir=/tmp


[Fri May 17 14:43:41 2024]
localrule fastqc:
    input: data/sampels/070_001_240321_001_0355_099_01_4691_2.fq.gz
    output: results/00_fastqc/070_001_240321_001_0355_099_01_4691_2_fastqc
    log: logs/070_001_240321_001_0355_099_01_4691_2.log
    jobid: 2
    reason: Missing output files: results/00_fastqc/070_001_240321_001_0355_099_01_4691_2_fastqc
    wildcards: names=070_001_240321_001_0355_099_01_4691, con=2
    resources: tmpdir=/tmp


[Fri May 17 14:43:41 2024]
localrule fastqc:
    input: data/sampels/070_001_240321_001_0355_099_01_4691_1.fq.gz
    output: results/00_fastqc/070_001_240321_001_0355_099_01_4691_1_fastqc
    log: logs/070_001_240321_001_0355_099_01_4691_1.log
    jobid: 1
    reason: Missing output files: results/00_fastqc/070_001_240321_001_0355_099_01_4691_1_fastqc
    wildcards: names=070_001_240321_001_0355_099_01_4691, con=1
    resources: tmpdir=/tmp


[Fri May 17 14:43:41 2024]
localrule fastqc:
    input: data/sampels/070_001_240321_001_0356_099_01_4691_2.fq.gz
    output: results/00_fastqc/070_001_240321_001_0356_099_01_4691_2_fastqc
    log: logs/070_001_240321_001_0356_099_01_4691_2.log
    jobid: 4
    reason: Missing output files: results/00_fastqc/070_001_240321_001_0356_099_01_4691_2_fastqc
    wildcards: names=070_001_240321_001_0356_099_01_4691, con=2
    resources: tmpdir=/tmp

Analysis complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Analysis complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
[Fri May 17 14:44:16 2024]
Finished job 4.
1 of 5 steps (20%) done
[Fri May 17 14:44:17 2024]
Finished job 3.
2 of 5 steps (40%) done
Analysis complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
[Fri May 17 14:44:39 2024]
Finished job 1.
3 of 5 steps (60%) done
Analysis complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
[Fri May 17 14:44:41 2024]
Finished job 2.
4 of 5 steps (80%) done
Select jobs to execute...
Execute 1 jobs...

[Fri May 17 14:44:41 2024]
localrule all:
    input: results/00_fastqc/070_001_240321_001_0355_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0355_099_01_4691_2_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_2_fastqc
    jobid: 0
    reason: Input files updated by another job: results/00_fastqc/070_001_240321_001_0356_099_01_4691_2_fastqc, results/00_fastqc/070_001_240321_001_0355_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0355_099_01_4691_2_fastqc
    resources: tmpdir=/tmp

[Fri May 17 14:44:41 2024]
Finished job 0.
5 of 5 steps (100%) done
Complete log: .snakemake/log/2024-05-17T144340.504787.snakemake.log
````
So what happend: It will make all the preparations, then it will perform the rule, then It will check by the rule all if all the out^put is already there, if not it will perform the rule again till the rule all every combination of variables exist. 

## adding the rest of steps 
### multiqc
I will start with multiqc, I added the following part: 
````
rule multiqc:
    input:
        expand("results/00_fastqc/{names}_{con}_fastqc/", names=sample_names, con = CONDITIONS),
        "results/00_fastqc/"
    output:
        "results/01_multiqc/multiqc_report.html",
        result = directory("results/01_multiqc/")  
    log:
        "logs/multiqc.log"
    conda:
        "envs/multiqc.yml"
    shell:
        """
        multiqc {input[1]} -o {output.result} 2>> {log}
        """
````
This worked. 

output:
````
/home/genomics/mhannaert/snakemake/Illuminapipeline
['070_001_240321_001_0355_099_01_4691']
['070_001_240321_001_0355_099_01_4691', '070_001_240321_001_0356_099_01_4691']
Building DAG of jobs...
Your conda installation is not configured to use strict channel priorities. This is however crucial for having robust and correct environments (for details, see https://conda-forge.org/docs/user/tipsandtricks.html). Please consider to configure strict priorities by executing 'conda config --set channel_priority strict'.
Retrieving input from storage.
Using shell: /usr/bin/bash
Provided cores: 4
Rules claiming more threads will be scaled down.
Job stats:
job        count
-------  -------
all            1
multiqc        1
total          2

Select jobs to execute...
Execute 1 jobs...

[Fri May 17 15:46:56 2024]
localrule multiqc:
    input: results/00_fastqc/070_001_240321_001_0355_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0355_099_01_4691_2_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_2_fastqc, results/00_fastqc
    output: results/01_multiqc/multiqc_report.html, results/01_multiqc
    log: logs/multiqc.log
    jobid: 5
    reason: Missing output files: results/01_multiqc/multiqc_report.html; Code has changed since last execution
    resources: tmpdir=/tmp

Activating conda environment: .snakemake/conda/f603d5f182bf6b4214b829cdb04e8efc_
[Fri May 17 15:47:14 2024]
Finished job 5.
1 of 2 steps (50%) done
Select jobs to execute...
Execute 1 jobs...

[Fri May 17 15:47:14 2024]
localrule all:
    input: results/00_fastqc/070_001_240321_001_0355_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0355_099_01_4691_2_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_2_fastqc, results/01_multiqc/multiqc_report.html
    jobid: 0
    reason: Input files updated by another job: results/01_multiqc/multiqc_report.html
    resources: tmpdir=/tmp

[Fri May 17 15:47:14 2024]
Finished job 0.
2 of 2 steps (100%) done
Complete log: .snakemake/log/2024-05-17T154654.246478.snakemake.log
````
### Kraken2 and Krona
I added:
````
rule Kraken2:
    input:
        "data/sampels/{names}_{con}.fq.gz"
    output:
        "results/02_kraken2/{names}_{con}_kraken2.report"
    params:
        threads=16
    log:
        "logs/Kraken2_{names}_{con}.log"
    shell:
        """
        kraken2 --gzip-compressed {input} --db /var/db/kraken2/Standard --report {output} --threads {params.threads} --quick --memory-mapping 2>> {log}
        """

rule Krona:
    input:
        "results/02_kraken2/{names}_{con}_kraken2.report"
    output:
        "results/03_krona/{names}_{con}_krona.html"
    params:
        extra="-t 5 -m 3"
    log:
        "logs/Krona_{names}_{con}.log"
    conda:
        "envs/krona.yml"
    shell:
        """
        ktImportTaxonomy {params.extra} -o {output} {input} 2>> {log}
        """
````
Kraken worked but there went something wrong with the krona, this is the content of the log file:
````
Building DAG of jobs...
Your conda installation is not configured to use strict channel priorities. This is however crucial for having robust and correct environments (for details, see https://conda-forge.org/docs/user/tipsandtricks.html). Please consider to configure strict priorities by executing 'conda config --set channel_priority strict'.
Creating conda environment envs/krona.yml...
Downloading and installing remote packages.
Environment for /home/genomics/mhannaert/snakemake/Illuminapipeline/envs/krona.yml created (location: .snakemake/conda/cce02dcec3898e2025b146bc478991b8_)
Retrieving input from storage.
Using shell: /usr/bin/bash
Provided cores: 4
Rules claiming more threads will be scaled down.
Job stats:
job        count
-------  -------
Kraken2        4
Krona          4
all            1
total          9

Select jobs to execute...
Execute 4 jobs...

[Fri May 17 15:57:47 2024]
localrule Kraken2:
    input: data/sampels/070_001_240321_001_0356_099_01_4691_1.fq.gz
    output: results/02_kraken2/070_001_240321_001_0356_099_01_4691_1_kraken2.report
    log: logs/070_001_240321_001_0356_099_01_4691_1_Kraken2.log
    jobid: 8
    reason: Missing output files: results/02_kraken2/070_001_240321_001_0356_099_01_4691_1_kraken2.report
    wildcards: names=070_001_240321_001_0356_099_01_4691, con=1
    resources: tmpdir=/tmp


[Fri May 17 15:57:47 2024]
localrule Kraken2:
    input: data/sampels/070_001_240321_001_0356_099_01_4691_2.fq.gz
    output: results/02_kraken2/070_001_240321_001_0356_099_01_4691_2_kraken2.report
    log: logs/070_001_240321_001_0356_099_01_4691_2_Kraken2.log
    jobid: 9
    reason: Missing output files: results/02_kraken2/070_001_240321_001_0356_099_01_4691_2_kraken2.report
    wildcards: names=070_001_240321_001_0356_099_01_4691, con=2
    resources: tmpdir=/tmp


[Fri May 17 15:57:47 2024]
localrule Kraken2:
    input: data/sampels/070_001_240321_001_0355_099_01_4691_2.fq.gz
    output: results/02_kraken2/070_001_240321_001_0355_099_01_4691_2_kraken2.report
    log: logs/070_001_240321_001_0355_099_01_4691_2_Kraken2.log
    jobid: 7
    reason: Missing output files: results/02_kraken2/070_001_240321_001_0355_099_01_4691_2_kraken2.report
    wildcards: names=070_001_240321_001_0355_099_01_4691, con=2
    resources: tmpdir=/tmp


[Fri May 17 15:57:47 2024]
localrule Kraken2:
    input: data/sampels/070_001_240321_001_0355_099_01_4691_1.fq.gz
    output: results/02_kraken2/070_001_240321_001_0355_099_01_4691_1_kraken2.report
    log: logs/070_001_240321_001_0355_099_01_4691_1_Kraken2.log
    jobid: 6
    reason: Missing output files: results/02_kraken2/070_001_240321_001_0355_099_01_4691_1_kraken2.report
    wildcards: names=070_001_240321_001_0355_099_01_4691, con=1
    resources: tmpdir=/tmp

[Fri May 17 16:13:19 2024]
Finished job 9.
1 of 9 steps (11%) done
Select jobs to execute...
Execute 1 jobs...

[Fri May 17 16:13:23 2024]
localrule Krona:
    input: results/02_kraken2/070_001_240321_001_0356_099_01_4691_2_kraken2.report
    output: results/03_krona/070_001_240321_001_0356_099_01_4691_2_krona.html
    log: logs/070_001_240321_001_0356_099_01_4691_2_Krona.log
    jobid: 13
    reason: Missing output files: results/03_krona/070_001_240321_001_0356_099_01_4691_2_krona.html; Input files updated by another job: results/02_kraken2/070_001_240321_001_0356_099_01_4691_2_kraken2.report
    wildcards: names=070_001_240321_001_0356_099_01_4691, con=2
    resources: tmpdir=/tmp

Activating conda environment: .snakemake/conda/cce02dcec3898e2025b146bc478991b8_
[Fri May 17 16:13:25 2024]
Finished job 8.
2 of 9 steps (22%) done
Select jobs to execute...
Execute 1 jobs...

[Fri May 17 16:13:29 2024]
[Fri May 17 16:13:29 2024]
Error in rule Krona:
    jobid: 13
    input: results/02_kraken2/070_001_240321_001_0356_099_01_4691_2_kraken2.report
    output: results/03_krona/070_001_240321_001_0356_099_01_4691_2_krona.html
    log: logs/070_001_240321_001_0356_099_01_4691_2_Krona.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/cce02dcec3898e2025b146bc478991b8_
    shell:
        
        ktImportTaxonomy -t 5 -m 3 -o results/03_krona/070_001_240321_001_0356_099_01_4691_2_krona.html results/02_kraken2/070_001_240321_001_0356_099_01_4691_2_kraken2.report 2>> logs/070_001_240321_001_0356_099_01_4691_2_Krona.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

localrule Krona:
    input: results/02_kraken2/070_001_240321_001_0356_099_01_4691_1_kraken2.report
    output: results/03_krona/070_001_240321_001_0356_099_01_4691_1_krona.html
    log: logs/070_001_240321_001_0356_099_01_4691_1_Krona.log
    jobid: 12
    reason: Missing output files: results/03_krona/070_001_240321_001_0356_099_01_4691_1_krona.html; Input files updated by another job: results/02_kraken2/070_001_240321_001_0356_099_01_4691_1_kraken2.report
    wildcards: names=070_001_240321_001_0356_099_01_4691, con=1
    resources: tmpdir=/tmp

Activating conda environment: .snakemake/conda/cce02dcec3898e2025b146bc478991b8_
[Fri May 17 16:13:32 2024]
Error in rule Krona:
    jobid: 12
    input: results/02_kraken2/070_001_240321_001_0356_099_01_4691_1_kraken2.report
    output: results/03_krona/070_001_240321_001_0356_099_01_4691_1_krona.html
    log: logs/070_001_240321_001_0356_099_01_4691_1_Krona.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/cce02dcec3898e2025b146bc478991b8_
    shell:
        
        ktImportTaxonomy -t 5 -m 3 -o results/03_krona/070_001_240321_001_0356_099_01_4691_1_krona.html results/02_kraken2/070_001_240321_001_0356_099_01_4691_1_kraken2.report 2>> logs/070_001_240321_001_0356_099_01_4691_1_Krona.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

[Fri May 17 16:18:45 2024]
Finished job 6.
3 of 9 steps (33%) done
[Fri May 17 16:18:50 2024]
Finished job 7.
4 of 9 steps (44%) done
Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-17T155702.055817.snakemake.log
WorkflowError:
At least one job did not complete successfully.
````
I asked my supervisor for this error, apparently to use krona you first have to execute a certain script updateTaxonomy.sh (https://github.com/marbl/Krona/wiki/Installing) before you can use the tool -> "This will install the local taxonomy database, which uses less than 100Mb of disk space and should take a few minutes or less to run. It can also be run later to keep the local database up to date with NCBI."


Now I runned my Snakemake again: 
````
/home/genomics/mhannaert/snakemake/Illuminapipeline
['070_001_240321_001_0355_099_01_4691']
['070_001_240321_001_0355_099_01_4691', '070_001_240321_001_0356_099_01_4691']
Building DAG of jobs...
Your conda installation is not configured to use strict channel priorities. This is however crucial for having robust and correct environments (for details, see https://conda-forge.org/docs/user/tipsandtricks.html). Please consider to configure strict priorities by executing 'conda config --set channel_priority strict'.
Retrieving input from storage.
Using shell: /usr/bin/bash
Provided cores: 4
Rules claiming more threads will be scaled down.
Job stats:
job      count
-----  -------
Krona        4
all          1
total        5

Select jobs to execute...
Execute 4 jobs...

[Fri May 17 16:47:58 2024]
localrule Krona:
    input: results/02_kraken2/070_001_240321_001_0355_099_01_4691_1_kraken2.report
    output: results/03_krona/070_001_240321_001_0355_099_01_4691_1_krona.html
    log: logs/Krona_070_001_240321_001_0355_099_01_4691_1.log
    jobid: 10
    reason: Missing output files: results/03_krona/070_001_240321_001_0355_099_01_4691_1_krona.html
    wildcards: names=070_001_240321_001_0355_099_01_4691, con=1
    resources: tmpdir=/tmp

Activating conda environment: .snakemake/conda/cce02dcec3898e2025b146bc478991b8_

[Fri May 17 16:47:58 2024]
localrule Krona:
    input: results/02_kraken2/070_001_240321_001_0355_099_01_4691_2_kraken2.report
    output: results/03_krona/070_001_240321_001_0355_099_01_4691_2_krona.html
    log: logs/Krona_070_001_240321_001_0355_099_01_4691_2.log
    jobid: 11
    reason: Missing output files: results/03_krona/070_001_240321_001_0355_099_01_4691_2_krona.html
    wildcards: names=070_001_240321_001_0355_099_01_4691, con=2
    resources: tmpdir=/tmp

Activating conda environment: .snakemake/conda/cce02dcec3898e2025b146bc478991b8_

[Fri May 17 16:47:58 2024]
localrule Krona:
    input: results/02_kraken2/070_001_240321_001_0356_099_01_4691_2_kraken2.report
    output: results/03_krona/070_001_240321_001_0356_099_01_4691_2_krona.html
    log: logs/Krona_070_001_240321_001_0356_099_01_4691_2.log
    jobid: 13
    reason: Missing output files: results/03_krona/070_001_240321_001_0356_099_01_4691_2_krona.html
    wildcards: names=070_001_240321_001_0356_099_01_4691, con=2
    resources: tmpdir=/tmp

Activating conda environment: .snakemake/conda/cce02dcec3898e2025b146bc478991b8_

[Fri May 17 16:47:58 2024]
localrule Krona:
    input: results/02_kraken2/070_001_240321_001_0356_099_01_4691_1_kraken2.report
    output: results/03_krona/070_001_240321_001_0356_099_01_4691_1_krona.html
    log: logs/Krona_070_001_240321_001_0356_099_01_4691_1.log
    jobid: 12
    reason: Missing output files: results/03_krona/070_001_240321_001_0356_099_01_4691_1_krona.html
    wildcards: names=070_001_240321_001_0356_099_01_4691, con=1
    resources: tmpdir=/tmp

Activating conda environment: .snakemake/conda/cce02dcec3898e2025b146bc478991b8_
Loading taxonomy...
Loading taxonomy...
Loading taxonomy...
Loading taxonomy...
Importing results/02_kraken2/070_001_240321_001_0355_099_01_4691_1_kraken2.report...
Importing results/02_kraken2/070_001_240321_001_0356_099_01_4691_1_kraken2.report...
Writing results/03_krona/070_001_240321_001_0355_099_01_4691_1_krona.html...
Importing results/02_kraken2/070_001_240321_001_0356_099_01_4691_2_kraken2.report...
Importing results/02_kraken2/070_001_240321_001_0355_099_01_4691_2_kraken2.report...
Writing results/03_krona/070_001_240321_001_0356_099_01_4691_1_krona.html...
Writing results/03_krona/070_001_240321_001_0356_099_01_4691_2_krona.html...
Writing results/03_krona/070_001_240321_001_0355_099_01_4691_2_krona.html...
[Fri May 17 16:48:05 2024]
Finished job 10.
1 of 5 steps (20%) done
[Fri May 17 16:48:05 2024]
Finished job 12.
2 of 5 steps (40%) done
[Fri May 17 16:48:06 2024]
Finished job 11.
3 of 5 steps (60%) done
[Fri May 17 16:48:06 2024]
Finished job 13.
4 of 5 steps (80%) done
Select jobs to execute...
Execute 1 jobs...

[Fri May 17 16:48:06 2024]
localrule all:
    input: results/00_fastqc/070_001_240321_001_0355_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0355_099_01_4691_2_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_2_fastqc, results/01_multiqc/multiqc_report.html, results/02_kraken2/070_001_240321_001_0355_099_01_4691_1_kraken2.report, results/02_kraken2/070_001_240321_001_0355_099_01_4691_2_kraken2.report, results/02_kraken2/070_001_240321_001_0356_099_01_4691_1_kraken2.report, results/02_kraken2/070_001_240321_001_0356_099_01_4691_2_kraken2.report, results/03_krona/070_001_240321_001_0355_099_01_4691_1_krona.html, results/03_krona/070_001_240321_001_0355_099_01_4691_2_krona.html, results/03_krona/070_001_240321_001_0356_099_01_4691_1_krona.html, results/03_krona/070_001_240321_001_0356_099_01_4691_2_krona.html
    jobid: 0
    reason: Input files updated by another job: results/03_krona/070_001_240321_001_0355_099_01_4691_1_krona.html, results/03_krona/070_001_240321_001_0355_099_01_4691_2_krona.html, results/03_krona/070_001_240321_001_0356_099_01_4691_1_krona.html, results/03_krona/070_001_240321_001_0356_099_01_4691_2_krona.html
    resources: tmpdir=/tmp

[Fri May 17 16:48:06 2024]
Finished job 0.
5 of 5 steps (100%) done
Complete log: .snakemake/log/2024-05-17T164755.516751.snakemake.log
````
So these steps also worked. 
## Feedback 
I got some feedback on my snakefile on the following part: 
````
import os

CONDITIONS = ["1", "2"]
DIRS = ["00_fastqc","01_multiqc", "02_kraken2","03_krona"]

# Define directories
REFDIR = "/home/genomics/mhannaert/snakemake/Illuminapipeline/"
sample_dir = REFDIR+"data/sampels/"
result_dir = REFDIR+"results/"
os.chdir(REFDIR)

print(os.getcwd())
sample_names = []
sample_list = os.listdir(sample_dir)
for i in range(len(sample_list)):
    sample = sample_list[i]
    if sample.endswith("_1.fq.gz"):
        samples = sample.split("_1.fq")[0]
        sample_names.append(samples)
        print(sample_names)

for dir in DIRS:
    if os.path.isdir("results/"+dir) == False:
        os.mkdir("results/"+dir)
````
The "REFDIR" was not a great idea, because a snakemake must be shareble so the hard coding the directory must be changed to something more for everybody. 
My supervisor said it would be a good idea to change it to "." for the current working directory of use the "os.getcwd(). 
Also he said that the result dir doesn't need to be made before, and that when it is defined in the rule all it will be made so that my steps are not necessary, so I changed it to the following: 
````
import os

CONDITIONS = ["1", "2"]
#DIRS = ["00_fastqc","01_multiqc", "02_kraken2","03_krona"]

# Define directories
REFDIR = os.getcwd()
sample_dir = REFDIR+"data/sampels/"
result_dir = REFDIR+"results/"

sample_names = []
sample_list = os.listdir(sample_dir)
for i in range(len(sample_list)):
    sample = sample_list[i]
    if sample.endswith("_1.fq.gz"):
        samples = sample.split("_1.fq")[0]
        sample_names.append(samples)
        print(sample_names)

#for dir in DIRS:
#    if os.path.isdir("results/"+dir) == False:
#        os.mkdir("results/"+dir)
````
I changed it to os.getcwd() and I outcommanded the directories, because I will first check if it works with the following steps. If it works I will remove the part. 

## Next steps 
after the last steps I will add the following steps for the pipeline: fastp, shovill, skani, quast, busco 
### fastp 
I added the following parts : 
````
rule all:
    input:
        expand("results/00_fastqc/{names}_{con}_fastqc/", names=sample_names, con = CONDITIONS),
        "results/01_multiqc/multiqc_report.html",
        expand("results/02_kraken2/{names}_{con}_kraken2.report", names=sample_names, con = CONDITIONS),
        expand("results/03_krona/{names}_{con}_krona.html", names=sample_names, con = CONDITIONS),
        expand("results/04_fastp/{names}_1.fq.gz", names=sample_names),
        expand("results/04_fastp/{names}_2.fq.gz", names=sample_names),
        expand("results/04_fastp/{names}_fastp.html", names=sample_names),
        expand("results/04_fastp/{names}_fastp.json", names=sample_names)

rule Fastp:
    input:
        first = "data/sampels/{names}_1.fq.gz",
        second = "data/sampels/{names}_2.fq.gz"
    output:
        first = "results/04_fastp/{names}_1.fq.gz",
        second = "results/04_fastp/{names}_2.fq.gz",
        html = "results/04_fastp/{names}_fastp.html",
        json = "results/04_fastp/{names}_fastp.json"
    params:
        extra="-w 32"
    log:
        "logs/fastp_{names}.log"
    shell:
        """
        fastp {params.extra} -i {input.first} -I {input.second} -o {output.first} -O {output.second} -h {output.html} -j {output.json} --detect_adapter_for_pe 2>> {log}
        """
````
I runned the snakemake: 
````
['070_001_240321_001_0355_099_01_4691']
['070_001_240321_001_0355_099_01_4691', '070_001_240321_001_0356_099_01_4691']
Building DAG of jobs...
Your conda installation is not configured to use strict channel priorities. This is however crucial for having robust and correct environments (for details, see https://conda-forge.org/docs/user/tipsandtricks.html). Please consider to configure strict priorities by executing 'conda config --set channel_priority strict'.
Retrieving input from storage.
Using shell: /usr/bin/bash
Provided cores: 4
Rules claiming more threads will be scaled down.
Job stats:
job      count
-----  -------
Fastp        2
all          1
total        3

Select jobs to execute...
Execute 2 jobs...

[Tue May 21 10:00:14 2024]
localrule Fastp:
    input: data/sampels/070_001_240321_001_0356_099_01_4691_1.fq.gz, data/sampels/070_001_240321_001_0356_099_01_4691_2.fq.gz
    output: results/04_fastp/070_001_240321_001_0356_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_2.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_fastp.html, results/04_fastp/070_001_240321_001_0356_099_01_4691_fastp.json
    log: logs/fastp_070_001_240321_001_0356_099_01_4691.log
    jobid: 15
    reason: Missing output files: results/04_fastp/070_001_240321_001_0356_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_fastp.json, results/04_fastp/070_001_240321_001_0356_099_01_4691_2.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_fastp.html
    wildcards: names=070_001_240321_001_0356_099_01_4691
    resources: tmpdir=/tmp


[Tue May 21 10:00:14 2024]
localrule Fastp:
    input: data/sampels/070_001_240321_001_0355_099_01_4691_1.fq.gz, data/sampels/070_001_240321_001_0355_099_01_4691_2.fq.gz
    output: results/04_fastp/070_001_240321_001_0355_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691_2.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691_fastp.html, results/04_fastp/070_001_240321_001_0355_099_01_4691_fastp.json
    log: logs/fastp_070_001_240321_001_0355_099_01_4691.log
    jobid: 14
    reason: Missing output files: results/04_fastp/070_001_240321_001_0355_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691_2.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691_fastp.json, results/04_fastp/070_001_240321_001_0355_099_01_4691_fastp.html
    wildcards: names=070_001_240321_001_0355_099_01_4691
    resources: tmpdir=/tmp

[Tue May 21 10:00:51 2024]
Finished job 15.
1 of 3 steps (33%) done
[Tue May 21 10:01:00 2024]
Finished job 14.
2 of 3 steps (67%) done
Select jobs to execute...
Execute 1 jobs...

[Tue May 21 10:01:00 2024]
localrule all:
    input: results/00_fastqc/070_001_240321_001_0355_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0355_099_01_4691_2_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_1_fastqc, results/00_fastqc/070_001_240321_001_0356_099_01_4691_2_fastqc, results/01_multiqc/multiqc_report.html, results/02_kraken2/070_001_240321_001_0355_099_01_4691_1_kraken2.report, results/02_kraken2/070_001_240321_001_0355_099_01_4691_2_kraken2.report, results/02_kraken2/070_001_240321_001_0356_099_01_4691_1_kraken2.report, results/02_kraken2/070_001_240321_001_0356_099_01_4691_2_kraken2.report, results/03_krona/070_001_240321_001_0355_099_01_4691_1_krona.html, results/03_krona/070_001_240321_001_0355_099_01_4691_2_krona.html, results/03_krona/070_001_240321_001_0356_099_01_4691_1_krona.html, results/03_krona/070_001_240321_001_0356_099_01_4691_2_krona.html, results/04_fastp/070_001_240321_001_0355_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691_2.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_2.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691_fastp.html, results/04_fastp/070_001_240321_001_0356_099_01_4691_fastp.html, results/04_fastp/070_001_240321_001_0355_099_01_4691_fastp.json, results/04_fastp/070_001_240321_001_0356_099_01_4691_fastp.json
    jobid: 0
    reason: Input files updated by another job: results/04_fastp/070_001_240321_001_0355_099_01_4691_fastp.json, results/04_fastp/070_001_240321_001_0355_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691_2.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_fastp.html, results/04_fastp/070_001_240321_001_0356_099_01_4691_2.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691_fastp.html, results/04_fastp/070_001_240321_001_0356_099_01_4691_fastp.json
    resources: tmpdir=/tmp

[Tue May 21 10:01:00 2024]
Finished job 0.
3 of 3 steps (100%) done
Complete log: .snakemake/log/2024-05-21T100012.011237.snakemake.log
````
It worked, als the directory was made so I think the part can be removed. 

### shovill 
I will added the rule for shovill: 
````
rule shovill:
    input:
        first = "results/04_fastp/{names}_1.fq.gz",
        second = "results/04_fastp/{names}_2.fq.gz"
    output: 
        result = directory("results/05_shovill/{names}/")
    params:
        extra = "--cpus 16 --ram 16 --minlen 500 --trim"
    log:
        "logs/shovill_{names}.log"
    conda:
        "envs/shovill.yml"
    shell:
        """
        shovill --R1 {input.first} --R2 {input.second} {params.extra} -outdir {output.result} 2>> {log}
        """
````
I runned the snakemake and this part also worked. 

### rule for collecting contig.fa files 
The directory **assemblies/** must be made to collect the contigs.fa files. this is needed for the following steps. 
I will collect the files and also rename them because otherwise you won't know which file it is in later steps. 
````
rule contigs:
    input:
        "results/05_shovill/{names}/contigs.fa"
    output:
        "results/assemblies/{names}.fna"
    shell:
        """
        cp {input} {output}
        """
````
This worked. 

### Skani
This is what I added:
````
rule skani:
    input:
        "results/assemblies/{names}.fna"
    output:
        "06_skani/skani_results_file.txt"
    params:
        extra = "-t 24 -n 1"
    log:
        "logs/skani_{names}.log"
    conda:
       "envs/skani.yml" 
    shell:
        """
        skani search {input} -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o {output} {params.extra} 2>> {log}
        """
````
I runned snakemake and got the following error: 
````
['070_001_240321_001_0355_099_01_4691']
['070_001_240321_001_0355_099_01_4691', '070_001_240321_001_0356_099_01_4691']
Building DAG of jobs...
WildcardError in rule skani in file /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile, line 137:
Wildcards in input files cannot be determined from output files: (rule skani, line 291, /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile)
'names'
````
I removed out of the input part the {names part.}, 
This was also not the solution because I got the following error: 
````
['070_001_240321_001_0355_099_01_4691']
['070_001_240321_001_0355_099_01_4691', '070_001_240321_001_0356_099_01_4691']
Building DAG of jobs...
Your conda installation is not configured to use strict channel priorities. This is however crucial for having robust and correct environments (for details, see https://conda-forge.org/docs/user/tipsandtricks.html). Please consider to configure strict priorities by executing 'conda config --set channel_priority strict'.
Creating conda environment envs/skani.yml...
Downloading and installing remote packages.
Environment for /home/genomics/mhannaert/snakemake/Illuminapipeline/envs/skani.yml created (location: .snakemake/conda/f45ccea93d9beb725ff7f59e3308f90f_)
Retrieving input from storage.
Using shell: /usr/bin/bash
Provided cores: 4
Rules claiming more threads will be scaled down.
Job stats:
job      count
-----  -------
all          1
skani        1
total        2

Select jobs to execute...
Execute 1 jobs...

[Tue May 21 11:40:54 2024]
localrule skani:
    input: results/assemblies
    output: results/06_skani/skani_results_file.txt
    log: logs/skani.log
    jobid: 20
    reason: Missing output files: results/06_skani/skani_results_file.txt
    resources: tmpdir=/tmp

Activating conda environment: .snakemake/conda/f45ccea93d9beb725ff7f59e3308f90f_
[Tue May 21 11:40:54 2024]
Error in rule skani:
    jobid: 20
    input: results/assemblies
    output: results/06_skani/skani_results_file.txt
    log: logs/skani.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/f45ccea93d9beb725ff7f59e3308f90f_
    shell:
        
        skani search results/assemblies -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o results/06_skani/skani_results_file.txt -t 24 -n 1 2>> logs/skani.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-21T114028.388209.snakemake.log
WorkflowError:
At least one job did not complete successfully.
````
I went looking in to the log file of skani in **/home/genomics/mhannaert/snakemake/Illuminapipeline/logs/skani.log**
And there stood the following: /usr/bin/bash: line 2: skani: command not found

this means there is something wrong, maybe I don't have the conda env correctly or I need to do something first like with krona before. 

I started with changing the envs for conda maybe I made  typo. 
I checked and it was not a typo, so I went to the github page of skani to look at the installation of the tool. 
Here there stood nothing special about skani installation or thing you need to do before you start. 

Because I could not find why the skani command won't work I asked my supervisor, Oke so he checked for me I when I have exported my env I made a mistake because I exported my base env instead, and thats indeed the reason why skani wasn't recoginised. 

so I changed it ( and all the rest of my env , because these needed to be .yaml and not .Yml) and I tried again. 

It didn't gave the output I wanted, so I changed it back the input to {names}.fna
tested again: 
````
WildcardError in rule skani in file /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile, line 137:
Wildcards in input files cannot be determined from output files: (rule skani, line 291, /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile)
'names'
````
I solved it in the following way: 
````
rule skani:
    input:
        "results/assemblies"
    output:
        result = "results/06_skani/skani_results_file.txt"
    params:
        extra = "-t 24 -n 1"
    log:
        "logs/skani.log"
    conda:
       "envs/skani.yaml"
    shell:
        """
        skani search {input}/*.fna -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o {output} {params.extra} 2>> {log}
        """
````
This worked. 

### quast
I added the following part: 
````
rule quast:
    input:
        "results/assemblies/{names}.fna"
    output:
        directory("results/07_quast/{names}/")
    log:
        "logs/quast_{names}.log"
    conda:
        "envs/quast.yaml"
    shell:
        """
        quast.py {input} -o {output}
        """
````
### making quast summarytable 
I added the part for the summary table: 
````
rule summarytable:
    input:
        "results/07_quast/"
    output: 
        "results/07_quast/quast_summary_table.txt"
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
````
I performed the snakemake and it worked. 

### making xlsx skani and quast
````
rule xlsx:
    input:
        "results/07_quast/quast_summary_table.txt",
        "results/06_skani/skani_results_file.txt",
        result = "results/"
    output:
        "results/06_skani/skANI_Quast_output.xlsx"
    shell:
        """
          skani_quast_to_xlsx.py {input.result}
          mv results/skANI_Quast_output.xlsx results/06_skani/
        """
````
This worked 
### making beeswarm 
````
rule beeswarm:
    input:
        "results/07_quast/quast_summary_table.txt"
    output:
        "results/07_quast/beeswarm_vis_assemblies.png"
    shell: 
        """
            beeswarm_vis_assemblies.R {input}
            mv beeswarm_vis_assemblies.png results/07_quast/
        """
````
This worked.
### busco
````
rule busco:
    input: 
        "results/assemblies/{names}.fna"
    output:
        directory("results/08_busco/{names}")
    params:
        extra= "-m genome --auto-lineage-prok -c 32"
    log: 
        "logs/busco_{names}.log"
    conda:
        "envs/busco.yaml"
    shell:
        """
        busco -i {input} -o {output} {params.extra}
        """
````
it worked
### busco visualisatie 
````
rule buscosummary:
    input:
        "results/08_busco/"
    output:
        directory("results/busco_summary")
    conda:
        "envs/busco.yaml"
    shell:
        """
        mkdir -p {output}
        cp {input}*/*/short_summary.specific.burkholderiales_odb10.*.txt {output}
        cd {output}
        for i in $(seq 1 15 $(ls -1 | wc -l)); do
            echo "Verwerking van bestanden $i tot $((i+14))"
            mkdir -p part_"$i-$((i+14))"
            ls -1 | tail -n +$i | head -15 | while read file; do
                echo "Verwerking van bestand: $file"
                mv "$file" part_"$i-$((i+14))"
            done
            generate_plot.py -wd part_"$i-$((i+14))"
        done
        cd ../..
        rm -dr busco_downloads
````
I got the following error: 
mv: cannot move 'part_1-15' to a subdirectory of itself, 'part_1-15/part_1-15'mv: cannot move 'part_1-15' to a subdirectory of itself, 'part_1-15/part_1-15'

So I needed to change that part, a solution that was presented by blackbox AI was the following: 
To fix this error, you can modify the shell script to exclude the part_1-15 directory from the list of files to be moved. One way to do this is by using the find command instead of ls -1

So I changed it to the following part: 
````
rule buscosummary:
    input:
        "results/08_busco/"
    output:
        directory("results/busco_summary")
    conda:
        "envs/busco.yaml"
    shell:
        """
        mkdir -p {output}
        cp {input}*/*/short_summary.specific.burkholderiales_odb10.*.txt {output}
        cd {output}
        for i in $(seq 1 15 $(ls -1 | wc -l)); do
            echo "Verwerking van bestanden $i tot $((i+14))"
            mkdir -p part_"$i-$((i+14))"
            find . -maxdepth 1 -type f | tail -n +$i | head -15 | while read file; do
                echo "Verwerking van bestand: $file"
                mv "$file" part_"$i-$((i+14))"
            done
            generate_plot.py -wd part_"$i-$((i+14))"
        done
        cd ../..
        rm -dr busco_downloads
        """
````

This worked, so I think the first try of the snakemake pipeline is ready. 

## first big test
I will remove all the outputs now and run it one more time completely to see if all the steps are compatible. 
I also think with the pipeline I now have I can remove the Snakefile_org now. 
I also don't use the config file in my Snakemake pipeline SO I also will remove that one. 

I also already have a question for when this work, I want to add to remove the fasp files, because after shovill these aren't needed anymore, the same for the kraken2 files, but is it possible because I needed them to be there for other steps? 

but first the try run: 
first I will do the run without outputs that are made with the following command: 
````
snakemake -np 
````
I got the following error: 
````
MissingInputException in rule multiqc in file /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile, line 52:
Missing input files for rule multiqc:
    output: results/01_multiqc/multiqc_report.html, results/01_multiqc
    affected files:
        results/00_fastqc
````
I forgot in the beginning to remove the expand from the fastqc rule. 
There is like a bigger problem with the multiqc rule:
````
['070_001_240321_001_0355_099_01_4691']
['070_001_240321_001_0355_099_01_4691', '070_001_240321_001_0356_099_01_4691']
Building DAG of jobs...
MissingInputException in rule multiqc in file /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile, line 52:
Missing input files for rule multiqc:
    output: results/01_multiqc, results/01_multiqc/multiqc_report.html
    affected files:
        results/00_fastqc
````
I outcommanded the multiqc part so that I could check the rest but there are again multiple errors: 
````
/home/genomics/mhannaert/snakemake/Illuminapipeline
['070_001_240321_001_0355_099_01_4691']
['070_001_240321_001_0355_099_01_4691', '070_001_240321_001_0356_099_01_4691']
Building DAG of jobs...
MissingInputException in rule Fastp in file /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile, line 96:
Missing input files for rule Fastp:
    output: results/04_fastp/070_001_240321_001_0355_099_01_4691/contigs.fa_1.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691/contigs.fa_2.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691/contigs.fa_fastp.html, results/04_fastp/070_001_240321_001_0355_099_01_4691/contigs.fa_fastp.json
    wildcards: names=070_001_240321_001_0355_099_01_4691/contigs.fa
    affected files:
        data/samples/070_001_240321_001_0355_099_01_4691/contigs.fa_2.fq.gz
        data/samples/070_001_240321_001_0355_099_01_4691/contigs.fa_1.fq.gz
````
I changed a lot of things, 
but I still got the following error:
````
Building DAG of jobs...
MissingInputException in rule skani in file /home/genomics/mhannaert/snakemake/Illuminapipeline/Snakefile, line 139:
Missing input files for rule skani:
    output: results/06_skani/skani_results_file.txt
    affected files:
        results/assemblies
````
The error is still with the input diectories, when it is a diretory as input it gives errors. 

I send a message to my supervisor, the solution was very simple and I already had done that solution in the beginning with multiqc. 

I needed to use the expand funtion in the input
you can see the changes I made to the snake file under commit with the name, **solutions for errors first test**

now it's running and it looks like its working 

It didn't work but that error is for tommorow. 

## Further solving errors
I changed two times the input, like I put in input, so that the rule won't start before an other rule is done, but I hard coded the directory in the command because these directories will be made during the proces, thus this can be hard coded. 

It is now running, 
error with shovill, the following part can be found in the log files:
````
Error in rule shovill:
    jobid: 17
    input: results/04_fastp/070_001_240321_001_0356_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_2.fq.gz
    output: results/05_shovill/070_001_240321_001_0356_099_01_4691/contigs.fa, results/05_shovill/070_001_240321_001_0356_099_01_4691
    log: logs/shovill_070_001_240321_001_0356_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/e3a86a96aaf3a3c87981bc7f5086614f_
    shell:
        
        shovill --R1 results/04_fastp/070_001_240321_001_0356_099_01_4691_1.fq.gz --R2 results/04_fastp/070_001_240321_001_0356_099_01_4691_2.fq.gz --cpus 16 --ram 16 --minlen 500 --trim -outdir results/05_shovill/070_001_240321_001_0356_099_01_4691 2>> logs/shovill_070_001_240321_001_0356_099_01_4691.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)


[shovill] Folder 'results/05_shovill/070_001_240321_001_0356_099_01_4691' already exists. Try using --force
````

For a solution I added the "expand" to the shovill input so that it has to wait till fastp is ready, so that maybe the folder won't be made multiple times. 

I rerund: 
````
Error in rule shovill:
    jobid: 16
    input: results/04_fastp/070_001_240321_001_0355_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691_2.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_2.fq.gz
    output: results/05_shovill/070_001_240321_001_0355_099_01_4691/contigs.fa, results/05_shovill/070_001_240321_001_0355_099_01_4691
    log: logs/shovill_070_001_240321_001_0355_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/e3a86a96aaf3a3c87981bc7f5086614f_
    shell:
        
        shovill --R1 results/04_fastp/070_001_240321_001_0355_099_01_4691_1.fq.gz results/04_fastp/070_001_240321_001_0356_099_01_4691_1.fq.gz --R2 results/04_fastp/070_001_240321_001_0355_099_01_4691_2.fq.gz results/04_fastp/070_001_240321_001_0356_099_01_4691_2.fq.gz --cpus 16 --ram 16 --minlen 500 --trim -outdir results/05_shovill/070_001_240321_001_0355_099_01_4691 2>> logs/shovill_070_001_240321_001_0355_099_01_4691.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Error in rule shovill:
    jobid: 17
    input: results/04_fastp/070_001_240321_001_0355_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_1.fq.gz, results/04_fastp/070_001_240321_001_0355_099_01_4691_2.fq.gz, results/04_fastp/070_001_240321_001_0356_099_01_4691_2.fq.gz
    output: results/05_shovill/070_001_240321_001_0356_099_01_4691/contigs.fa, results/05_shovill/070_001_240321_001_0356_099_01_4691
    log: logs/shovill_070_001_240321_001_0356_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/e3a86a96aaf3a3c87981bc7f5086614f_
    shell:
        
        shovill --R1 results/04_fastp/070_001_240321_001_0355_099_01_4691_1.fq.gz results/04_fastp/070_001_240321_001_0356_099_01_4691_1.fq.gz --R2 results/04_fastp/070_001_240321_001_0355_099_01_4691_2.fq.gz results/04_fastp/070_001_240321_001_0356_099_01_4691_2.fq.gz --cpus 16 --ram 16 --minlen 500 --trim -outdir results/05_shovill/070_001_240321_001_0356_099_01_4691 2>> logs/shovill_070_001_240321_001_0356_099_01_4691.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

[shovill] Folder 'results/05_shovill/070_001_240321_001_0355_099_01_4691' already exists. Try using --force
````

I will try by adding the --force option, the result after running:
this option worked but I found a stupid error from me, at line 136 I do cd input, but input here is a file ..., so that won't work. I stopped the running and changed that. 


now  I will run again: 
````
[Wed May 22 11:29:18 2024]
Finished job 16.
17 of 29 steps (59%) done
Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-22T105139.782472.snakemake.log
WorkflowError:
At least one job did not complete successfully.
````
The problem is in the rule about contigs 
So again will take a look at that part`, with the help of blackbox AI I made the following solution: 
````
rule contigs:
    input:
        contigs_fa = "results/05_shovill/{names}/contigs.fa"
    output:
        assembly_fna = "results/assemblies/{names}.fna"
    shell:
        """
        cp {input.contigs_fa} {output.assembly_fna}
        """
````
when I runned it, starting from shovill, all teh following steps till busco part, there I got the following error: 
````
[Wed May 22 11:54:47 2024]
Finished job 27.
9 of 12 steps (75%) done
Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-22T115223.848693.snakemake.log
WorkflowError:
At least one job did not complete successfully.


Error in rule busco:
    jobid: 28
    input: results/assemblies/070_001_240321_001_0356_099_01_4691.fna
    output: results/08_busco/070_001_240321_001_0356_099_01_4691
    log: logs/busco_070_001_240321_001_0356_099_01_4691.log (check log file(s) for error details)
    conda-env: /home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/ab3b814a790df8a3227c1437cdffa761_
    shell:

        busco -i results/assemblies/070_001_240321_001_0356_099_01_4691.fna -o results/08_busco/070_001_240321_001_0356_099_01_4691 -m genome --auto-lineage-prok -c 32 2>> logs/busco_070_001_240321_001_0356_099_01_4691.log

        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

buscolog file: 
2024-05-22 11:54:24 CRITICAL:	Unhandled exception occurred:
Traceback (most recent call last):
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/ab3b814a790df8a3227c1437cdffa761_/lib/python3.9/site-packages/busco/BuscoRunner.py", line 120, in run
    self.get_lineage()
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/ab3b814a790df8a3227c1437cdffa761_/lib/python3.9/site-packages/busco/BuscoRunner.py", line 74, in get_lineage
    self.config.load_dataset(self.lineage_dataset)
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/ab3b814a790df8a3227c1437cdffa761_/lib/python3.9/site-packages/busco/BuscoConfig.py", line 227, in load_dataset
    self.download_lineage_file(
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/ab3b814a790df8a3227c1437cdffa761_/lib/python3.9/site-packages/busco/BuscoConfig.py", line 221, in download_lineage_file
    local_lineage_filepath = self.downloader.get(lineage, "lineages")
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/ab3b814a790df8a3227c1437cdffa761_/lib/python3.9/site-packages/busco/BuscoDownloadManager.py", line 236, in get
    local_filepath = self._decompress_file(
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/ab3b814a790df8a3227c1437cdffa761_/lib/python3.9/site-packages/busco/BuscoLogger.py", line 62, in wrapped_func
    self.retval = func(*args, **kwargs)
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/ab3b814a790df8a3227c1437cdffa761_/lib/python3.9/site-packages/busco/BuscoDownloadManager.py", line 335, in _decompress_file
    for line in compressed_file:
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/ab3b814a790df8a3227c1437cdffa761_/lib/python3.9/gzip.py", line 398, in readline
    return self._buffer.readline(size)
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/ab3b814a790df8a3227c1437cdffa761_/lib/python3.9/_compression.py", line 68, in readinto
    data = self.read(len(byte_view))
  File "/home/genomics/mhannaert/snakemake/Illuminapipeline/.snakemake/conda/ab3b814a790df8a3227c1437cdffa761_/lib/python3.9/gzip.py", line 506, in read
    raise EOFError("Compressed file ended before the "
EOFError: Compressed file ended before the end-of-stream marker was reached


2024-05-22 11:54:24 ERROR:	Compressed file ended before the end-of-stream marker was reached
2024-05-22 11:54:24 ERROR:	BUSCO analysis failed!
2024-05-22 11:54:24 ERROR:	Check the logs, read the user guide (https://busco.ezlab.org/busco_userguide.html), and check the BUSCO issue board on https://gitlab.com/ezlab/busco/issues
````

I think the most inportant part is the following: "Compressed file ended before the end-of-stream marker was reached"

but I don't know how I can fix that

I will just run again to see, 
