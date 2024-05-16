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