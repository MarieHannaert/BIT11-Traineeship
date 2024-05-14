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
