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
        #print(sample_names)
        
rule all:
    input:
        "results/quast/beeswarm_vis_assemblies.png",
        "results/busco_summary",
        "results/checkm/",
        "results/skANI_Quast_checkM2_output.xlsx"


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
rule beeswarm:
    input:
        "results/quast/quast_summary_table.txt"
    output:
        "results/quast/beeswarm_vis_assemblies.png"
    conda:
        "envs/beeswarm.yaml"
    log:
        "logs/beeswarm.log"
    shell: 
        """
        scripts/beeswarm_vis_assemblies.R {input} 2>> {log}
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
    log: 
        "logs/busco_summary.log"
    shell:
        """
        scripts/busco_summary.sh results/busco_summary 2>> {log}
        rm -dr busco_downloads
        rm busco*.log
        """
rule checkM:
    input:
       "data/assemblies/"
    output:
        directory("results/checkm/")
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
rule xlsx:
    input:
        "results/quast/quast_summary_table.txt",
        "results/skani/skani_results_file.txt",
        "results/checkM2/checkM2_summary_table.txt"
    output:
        "results/skANI_Quast_checkM2_output.xlsx"
    log:
        "logs/xlsx.log"
    shell:
        """
        scripts/skani_quast_checkm2_to_xlsx.py results/ 2>> {log}
        """
