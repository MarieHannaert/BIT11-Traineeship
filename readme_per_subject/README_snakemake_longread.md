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
This is not a nice error, I will solve it tommorw 
#### solving the error
I did the following: 
Escaping Curly Braces:

Original: {if(NR%4==1) {printf(">%s\n",substr($0,2));} else if(NR%4==2) print;}
Corrected: {{if(NR%4==1) {{printf(">%s\\n",substr($0,2));}} else if(NR%4==2) print;}}
In the corrected version, each { is replaced with {{ and each } is replaced with }}.

Escaping Newline Character:

Original: printf(">%s\n",substr($0,2));
Corrected: printf(">%s\\n",substr($0,2));
In the corrected version, the newline character \n is properly escaped as \\n.

By making these changes, you ensure that Snakemake correctly interprets the curly braces and the newline character within the awk command, preventing the ValueError from occurring.

Now I got an new error: 
````
[Tue May 28 09:11:23 2024]
Error in rule racon:
    jobid: 8
    input: results/03_porechopABI/GBBC502_OUTPUT.fasta, results/03_porechopABI/GBBC_504_sup_OUTPUT.fasta, results/04_flye/flye_out_GBBC502, results/04_flye/flye_out_GBBC_504_sup, results/05_racon/GBBC502_aln.paf.gz, results/05_racon/GBBC_504_sup_aln.paf.gz
    output: results/05_racon/GBBC502_racon.fasta
    log: logs/racon_GBBC502.log (check log file(s) for error details)
    shell:
        
        racon -u -t 16 results/03_porechopABI/GBBC502_OUTPUT.fasta results/03_porechopABI/GBBC_504_sup_OUTPUT.fasta results/05_racon/GBBC502_aln.paf.gz results/05_racon/GBBC_504_sup_aln.paf.gz results/04_flye/flye_out_GBBC502 results/04_flye/flye_out_GBBC_504_sup/assembly.fasta > results/05_racon/GBBC502_racon.fasta 2>> logs/racon_GBBC502.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Removing output files of failed job racon since they might be corrupted:
results/05_racon/GBBC502_racon.fasta
[Tue May 28 09:11:23 2024]
Error in rule racon:
    jobid: 15
    input: results/03_porechopABI/GBBC502_OUTPUT.fasta, results/03_porechopABI/GBBC_504_sup_OUTPUT.fasta, results/04_flye/flye_out_GBBC502, results/04_flye/flye_out_GBBC_504_sup, results/05_racon/GBBC502_aln.paf.gz, results/05_racon/GBBC_504_sup_aln.paf.gz
    output: results/05_racon/GBBC_504_sup_racon.fasta
    log: logs/racon_GBBC_504_sup.log (check log file(s) for error details)
    shell:
        
        racon -u -t 16 results/03_porechopABI/GBBC502_OUTPUT.fasta results/03_porechopABI/GBBC_504_sup_OUTPUT.fasta results/05_racon/GBBC502_aln.paf.gz results/05_racon/GBBC_504_sup_aln.paf.gz results/04_flye/flye_out_GBBC502 results/04_flye/flye_out_GBBC_504_sup/assembly.fasta > results/05_racon/GBBC_504_sup_racon.fasta 2>> logs/racon_GBBC_504_sup.log
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

LOGFILE:
[racon::createPolisher] error: file results/03_porechopABI/GBBC_504_sup_OUTPUT.fasta has unsupported format extension (valid extensions: .mhap, .mhap.gz, .paf, .paf.gz, .sam, .sam.gz)!
[racon::createPolisher] error: file results/03_porechopABI/GBBC_504_sup_OUTPUT.fasta has unsupported format extension (valid extensions: .mhap, .mhap.gz, .paf, .paf.gz, .sam, .sam.gz)!
````
I find this very strange error because I used the same input as in the script. It looks like he thinks it's already the next argument, because there these extensions are right

I changed the code by 
Direct File Paths vs. expand Function:

Original: Used expand function for each input to generate paths for all samples.
Corrected: Directly specified the paths using placeholders {names}.
Input flye Path:

Original: "results/04_flye/flye_out_{names}" (which might cause issues since the flye input does not point directly to the assembly file).
Corrected: "results/04_flye/flye_out_{names}/assembly.fasta" (points directly to the assembly file).
Order and Format of Arguments in racon Command:

Original: {input.porechop} {input.minimap} {input.flye}/assembly.fasta
Corrected: {input.porechop} {input.minimap} {input.flye}
This ensures that racon receives the correct files in the correct order:

Reads file (porechop)
Alignment file (minimap)
Assembly file (flye)

Now I got the following error: 
[racon::Polisher::initialize] loaded target sequences 0.021570 s
[racon::Polisher::initialize] loaded sequences 3.496450 s
[racon::Polisher::initialize] error: empty overlap set!

I went checking and indeed the minimap is empty. 

Oke after long searching I found that the error the use of exand was, when I removed this it all worked and there were no errors. 
I found out I didn't understand the expand option completly, I thougt it just just checked if the files were there all, I hadn't made the klick that it then also will use all these files at once. and that's were it twice went wrong. 
-> https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html

### skANI and quast + summaries
I just copied this part and changed the input from the snakefile of the illuminapipeline 

I tested this: 
skANI and Quast and Quast summary worked, the beeswarem not, error: "/usr/bin/bash: line 2: scripts/beeswarm_vis_assemblies.R: No such file or directory"

i forgot to add the scripts to the script folder. 

I runned again, 
following error: 
"Error in library(beeswarm) : there is no package called ‘beeswarm’
Execution halted"

So my conda env doesn't work

I found the following inf: https://github.com/conda-forge/r-beeswarm-feedstock
I performed that in my conda env r_beeswarm and I'm testing this now. 
This worked the visulaisation was done. 

### busco and summary
I added from the illumina snakemake the following part: 
````
rule busco:
    input: 
        "results/05_racon/{names}_racon.fasta"
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
        busco -i {input} -o {output} {params.extra} 2>> {log}
        """
````
The summary part wasn't a succes it took again only one sample, so we decided to make it in to a bash script and then use the bash script i the snakemake
#### BUsco summary script
this is the script I made: 
````
#!/bin/bash
# This script performs the summary of the BUSCO results based on the Illuminapipeline script.

# Define the base directory and the file to copy
base_dir="$1"


# Ensure the base directory exists and copy the specified file into it
mkdir -p "$base_dir"
echo "Making summary BUSCO"
for file in $(find -type f -name "short_summary.specific.burkholderiales_odb10.*.txt"); do
  cp "$file" "$base_dir"
done



# Count the total number of files (excluding directories)
total_files=$(find "$base_dir" -maxdepth 1 -type f | wc -l)

# Loop over the files in increments of 15
for i in $(seq 1 15 $total_files); do
  echo "Processing files $i to $((i+14))"
  sub_dir_name="$base_dir/part_$i-$((i+14))"
  mkdir -p "$sub_dir_name"
  
  # Move the files to the subdirectory
  find "$base_dir" -maxdepth 1 -type f | tail -n +$i | head -15 | while read -r file; do
    echo "Processing file: $file"
    mv "$file" "$sub_dir_name/"
  done
  
  # Optionally, run a script in the new subdirectory
  generate_plot.py -wd "$sub_dir_name"
done

# Optionally, remove the busco_downloads directory if it exists
# rm -dr "$base_dir/busco_downloads"

echo "Files have been organized into subdirectories."

# Optional: Go back to the parent directory
cd ..

# Optional: Remove the busco_downloads directory if it exists in the parent directory
rm -dr busco_downloads
````
I tested this script in the command line and it worked, now i'm testing it in a snakemake,
if it works I will also change this in the other pipelines

busco worked, summary not: 
````
Error in rule buscosummary:
    jobid: 22
    input: results/08_busco/GBBC502, results/08_busco/GBBC_504_sup
    output: results/busco_summary
    conda-env: /home/genomics/mhannaert/snakemake/Longreadpipeline/.snakemake/conda/26012719f62aa5ca70057d6e736d53eb_
    shell:
        
        scripts/busco_summary.sh results/busco_summary
        
        (one of the commands exited with non-zero exit code; note that snakemake uses bash strict mode!)

Removing output files of failed job buscosummary since they might be corrupted:
results/busco_summary
Shutting down, this might take some time.
Exiting because a job execution failed. Look above for error message
Complete log: .snakemake/log/2024-05-28T154601.918981.snakemake.log
WorkflowError:
At least one job did not complete successfully.
````
I removed the cd and rm command out of the script 
now it worked. 

so I think it will work completly now, i will do a big test tomorrow. 

## first big test
I runned the snakemake and it was a succes. everything is was made: 
````
[Wed May 29 09:53:58 2024]
Finished job 0.
25 of 25 steps (100%) done
Complete log: .snakemake/log/2024-05-29T090401.213223.snakemake.log
````
The change in the busco summary also worked perfect. 
So this pipeline is ready and the readme can be made. 

I will also make a dag graph and a report

## Feedback 
- the nanoplot is over writing itself -> give it a folder with name
- inbetween fq of porechop remove at the end 

so in the output I added the names part: 
````
rule nanoplot:
    input:
        expand("data/samples/{names}.fq.gz", names=sample_names)
    output: 
        "results/01_nanoplot/{names}/NanoPlot-report.html",
        result = directory("results/01_nanoplot/{names}")
    log:
        "logs/nanoplot_{names}.log"
    params:
        extra="-t 24"
    conda:
        "envs/nanoplot.yaml"
    shell:
        """
        NanoPlot {params.extra} --fastq data/samples/*.fq.gz -o {output.result} --plots --legacy hex dot 2>> {log}
        """
````

In the reformat rule I added the remove the intermedair: 
````
rule reformat:
    input:
        "results/03_porechopABI/{names}_trimmed.fq"
    output:
        "results/03_porechopABI/{names}_OUTPUT.fasta"
    shell:
        """
        cat {input} | awk '{{if(NR%4==1) {{printf(">%s\\n",substr($0,2));}} else if(NR%4==2) print;}}' > {output}
        rm results/03_porechopABI/{names}_trimmed.fq
        """
````
I will now test this again with these changes: 
It only did run till porechop, so went looking in the log file: 
````
[Wed May 29 11:39:50 2024]
localrule reformat:
    input: results/03_porechopABI/GBBC_504_sup_trimmed.fq
    output: results/03_porechopABI/GBBC_504_sup_OUTPUT.fasta
    jobid: 8
    reason: Missing output files: results/03_porechopABI/GBBC_504_sup_OUTPUT.fasta; Input files updated by another job: results/03_porechopABI/GBBC_504_sup_trimmed.fq
    wildcards: names=GBBC_504_sup
    resources: tmpdir=/tmp

RuleException in rule reformat in file /home/genomics/mhannaert/snakemake/Longreadpipeline/Snakefile, line 85:
NameError: The name 'names' is unknown in this context. Did you mean 'wildcards.names'?, when formatting the following:

        cat {input} | awk '{{if(NR%4==1) {{printf(">%s\n",substr($0,2));}} else if(NR%4==2) print;}}' > {output}
        rm results/03_porechopABI/{names}_trimmed.fq
        
````
yes, i made a mistake I needed to defin it in the shell part as input and not use the wildcard names. so I changed that. and tested again:
````
[Wed May 29 13:12:15 2024]
Finished job 0.
26 of 26 steps (100%) done
Complete log: .snakemake/log/2024-05-29T120946.133978.snakemake.log
````
so now after improving this it's ready 


