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
        #print(sample_names)
        
rule all:
    input:
        expand("results/01_nanoplot/{names}/NanoPlot-report.html", names=sample_names),
        "results/06_skani/skANI_Quast_output.xlsx",
        "results/07_quast/beeswarm_vis_assemblies.png",
        "results/busco_summary"

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
rule filtlong:
    input:
        "data/samples/{names}.fq.gz"
    output: 
        "results/02_filtlong/{names}_1000bp_100X.fq.gz"
    log:
        "logs/filtlong_{names}.log"
    params:
        extra="--min_length 1000 --target_bases 540000000 --keep_percent 95"
    conda:
        "envs/filtlong.yaml"
    shell:
        """
        filtlong {params.extra} {input} |  gzip > {output} 2>> {log}
        """
rule unzip:
    input:
        "data/samples/{names}.fq.gz",
        expand("results/02_filtlong/{names}_1000bp_100X.fq.gz", names=sample_names)
    output:
        "data/samples/{names}.fq"
    log:
        "logs/unzip_{names}.log"
    shell: 
        """
        pigz -dk {input[0]} 2>> {log}
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
rule reformat:
    input:
        "results/03_porechopABI/{names}_trimmed.fq"
    output:
        "results/03_porechopABI/{names}_OUTPUT.fasta"
    log:
        "logs/reformat_{names}.log"
    shell:
        """
        cat {input} | awk '{{if(NR%4==1) {{printf(">%s\\n",substr($0,2));}} else if(NR%4==2) print;}}' > {output} 2>> {log}
        rm {input}
        """

rule flye:
    input: 
        "results/03_porechopABI/{names}_OUTPUT.fasta"
    output:
        directory("results/04_flye/flye_out_{names}")
    log:
        "logs/flye_{names}.log"
    params:
        extra="--threads 32 --iterations 4 --scaffold"
    conda: 
        "envs/flye.yaml"
    shell:
        """
        flye --asm-coverage 50 --genome-size 5.4g --nano-hq {input} --out-dir {output} {params.extra} 2>> {log}
        """
rule minimap2:
    input: 
        porechop="results/03_porechopABI/{names}_OUTPUT.fasta",
        flye="results/04_flye/flye_out_{names}"
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
        minimap2 {params.extra} {input.flye}/assembly.fasta {input.porechop} | gzip - > {output} 2>> {log}
        """
rule racon:
    input: 
        porechop="results/03_porechopABI/{names}_OUTPUT.fasta",
        flye="results/04_flye/flye_out_{names}",
        minimap="results/05_racon/{names}_aln.paf.gz"
    output:
        "results/05_racon/{names}_racon.fasta"
    log:
        "logs/racon_{names}.log"
    conda: 
        "envs/racon.yaml"
    params: 
        extra="--include-unpolished -t 24"
    shell:
        """
        racon {params.extra} {input.porechop} {input.minimap} {input.flye}/assembly.fasta > {output} 2>> {log}
        """
rule skani:
    input:
        expand("results/05_racon/{names}_racon.fasta", names=sample_names)
    output:
        result = "results/06_skani/skani_results_file.txt"
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
        "results/05_racon/{names}_racon.fasta"
    output:
        directory("results/07_quast/{names}/")
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
        expand("results/07_quast/{names}", names = sample_names)
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
rule beeswarm:
    input:
        "results/07_quast/quast_summary_table.txt"
    output:
        "results/07_quast/beeswarm_vis_assemblies.png"
    conda:
        "envs/beeswarm.yaml"
    log:
        "logs/beeswarm.log"
    shell: 
        """
            scripts/beeswarm_vis_assemblies.R {input} 2>> {log}
            mv beeswarm_vis_assemblies.png results/07_quast/
        """
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
rule buscosummary:
    input:
        expand("results/08_busco/{names}", names=sample_names)
    output:
        directory("results/busco_summary")
    conda:
        "envs/busco.yaml"
    log:
        "logs/buscosummary.log"
    shell:
        """
        scripts/busco_summary.sh results/busco_summary 2>> {log}
        rm -dr busco_downloads
        rm busco*.log
        rm -dr tmp
        """
rule checkM:
    input:
       "data/assemblies/"
    output:
        directory("results/09_checkm/")
    params:
        extra="-t 24"
    log:
        "logs/checkM.log"
    conda:
        "envs/checkm.yaml"
    shell:
        """
        checkm lineage_wf {params.extra} {input} {output} 2>> {log}
        """
rule checkM2:
    input:
        "data/assemblies/{names}.fna"
    output:
        directory("results/10_checkM2/{names}")
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
rule summarytable_CheckM2:
    input:
        expand("results/10_checkM2/{names}", names = sample_names)
    output: 
        "results/10_checkM2/checkM2_summary_table.txt"
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
rule xlsx:
    input:
        "results/07_quast/quast_summary_table.txt",
        "results/06_skani/skani_results_file.txt",
        "results/10_checkM2/checkM2_summary_table.txt"
    output:
        "results/skANI_Quast_checkM2_output.xlsx"
    log:
        "logs/xlsx.log"
    shell:
        """
        scripts/skani_quast_checkm2_to_xlsx.py results/ 2>> {log}
        """
