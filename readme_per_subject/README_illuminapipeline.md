# Testing the Illumina pipeline

I tested all the stept from the Illuminapipeline to understand this pipeline. 
I also followed some tutorials from some tools. 

The data that I used to test this pipeline are a couple of sampoles copied from the genomics server. 

## fastqc 
Output is in the **/mhannaert/test_illuminapipelin/01_fastqc**
Output is in the **/mhannaert/test_illuminapipelin/01_fastqc_test**

For executing the fastqc I tried the working principle from above for multiple samples.  

I went looking for the fastqc to execute and why it woudn’t work, I forgot to give it execute premissions and there was no java installed for support.  

Installing java wasn’t simple I needed to update first ubuntu enviroment because otherwise it coudn’t find the java package.  

Now I tried to first bzip2 before running the fastqc, so that the file already is extracted. This worked.  

It appernetly doesn’t work on a bz2 file, so first I bzip2 all the files to gzip them after that. 

This is the command I used: 
````
$ fastqc -o ../01_fastqc/ --extract 070_001_240321_001_03* This worked 
````
I tried to write a small shell script for fastqc preforming on multiple samples, this script is based on the script of fastp.sh from Steve. -> fastqc_try.sh

## fastp
Output is in the **/mhannaert/test_illuminapipelin/02_fastp_test**

To perform this step I used the script of Steve.  I edited the input file in the script and edited the output file because I wanted my output in a file in a higher directory.  

script: /mhannaert/scripts/fastp.sh

## shovill
Output is in the **/mhannaert/test_illuminapipelin/03_shovill_test**

Output is in the **/mhannaert/test_illuminapipelin/03_shovill_test_server**

I installed this as a conda environment 

Assemble bacterial isolate genomes from Illumina paired-end reads. The SPAdes genome assembler has become the de facto standard de novo genome assembler for Illumina whole genome sequencing data of bacteria and other small microbes.  

I tried this with a script from Steve. I don’t get any output in my output directory.  

I preformed shovill by command for one file and I got an output in my output directory 

-> 
````
shovill --outdir 03_shovill_test/070_001_240321_001_0355_099_01_4691 --R1 02_fastp_test/070_001_240321_001_0355_099_01_4691_1.fq.gz --R2 02_fastp_test/070_001_240321_001_0355_099_01_4691_2.fq.gz 
````

An possible problem could be that pyyaml not is installed in my conda env, so no I will install that and retry. This was something Steve advised me as a solution.  -> this was all installed 

The next try I added before each directory “./” , this wasn’t a solution either 

We also have check in de conda env of everything was installed.  

We didn’t found a solution yet. So maybe it is my installation that went wrong.  

I removed the conda enviroment and reinstalled it but with a smaller command:  

-> 
````
mamba create --name shovill shovill 
````
I tried now the command from above again, this worked, but my supervisor told me to give some more arguments, more like:  

Now I tried it with the script in de WSL

We solved it by copying the conda part from the backup .bashrc file on the server to the real .bashrc file and sourced it again, that solved the problem.  

The script worked on the server.  

The output from this is in each directory of a sample the following: 

contigs.fa  contigs.gfa  shovill.corrections  shovill.log  spades.fasta 

The next step is quast, Quality Assessment Tool for Genome Assemblies by CAB 

I installed this as a conda environment.  

## quast
Output is in the **/mhannaert/test_illuminapipelin/04_quast_test**

Quality Assessment Tool for Genome Assemblies by CAB 

I installed this as a conda environment.  

Quast will look like this:  

WARNING: Python locale settings can't be changed 

/home/mhannaert/miniforge3/envs/quast/bin/quast.py 03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa -o 04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa 

Version: 5.0.2 

System information: 

  OS: Linux-4.4.0-19041-Microsoft-x86_64-with-debian-bookworm-sid (linux_64) 

  Python version: 3.6.15 

  CPUs number: 8 

Started: 2024-04-23 16:34:25 

Logging to /home/mhannaert/04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa/quast.log 

NOTICE: Maximum number of threads is set to 2 (use --threads option to set it manually) 

CWD: /home/mhannaert 

Main parameters: 

  MODE: default, threads: 2, minimum contig length: 500, minimum alignment length: 65, \ 

  ambiguity: one, threshold for extensive misassembly size: 1000 

Contigs: 

  Pre-processing... 

  03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa ==> contigs 

2024-04-23 16:34:28 

Running Basic statistics processor... 

  Contig files: 

    contigs 

  Calculating N50 and L50... 

    contigs, N50 = 110599, L50 = 14, Total length = 5239716, GC % = 66.76, # N's per 100 kbp =  0.00 

  Drawing Nx plot... 

    saved to /home/mhannaert/04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa/basic_stats/Nx_plot.pdf 

  Drawing cumulative plot... 

    saved to /home/mhannaert/04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa/basic_stats/cumulative_plot.pdf 

  Drawing GC content plot... 

    saved to /home/mhannaert/04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa/basic_stats/GC_content_plot.pdf 

  Drawing contigs GC content plot... 

    saved to /home/mhannaert/04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa/basic_stats/contigs_GC_content_plot.pdf 

Done. 

  

NOTICE: Genes are not predicted by default. Use --gene-finding or --glimmer option to enable it. 

  

2024-04-23 16:34:29 

Creating large visual summaries... 

This may take a while: press Ctrl-C to skip this step.. 

  1 of 2: Creating Icarus viewers... 

  2 of 2: Creating PDF with all tables and plots... 

Done 

2024-04-23 16:34:30 

RESULTS: 

  Text versions of total report are saved to /home/mhannaert/04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa/report.txt, report.tsv, and report.tex 

  Text versions of transposed total report are saved to /home/mhannaert/04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa/transposed_report.txt, transposed_report.tsv, and transposed_report.tex 

  HTML version (interactive tables and plots) is saved to /home/mhannaert/04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa/report.html 

  PDF version (tables and plots) is saved to /home/mhannaert/04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa/report.pdf 

  Icarus (contig browser) is saved to /home/mhannaert/04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa/icarus.html 

  Log is saved to /home/mhannaert/04_quast_test/03_shovill_test/070_001_240321_001_0355_099_01_4691/contigs.fa/quast.log 

  

Finished: 2024-04-23 16:34:30 

Elapsed time: 0:00:04.637555 

NOTICEs: 2; WARNINGs: 1; non-fatal ERRORs: 0 

  

Thank you for using QUAST! 

I used the following command:  
````
for f in 03_shovill_test/*/*.fa; do quast.py $f -o 04_quast_test/$f;done 
````

This gave me in my 04_quast_test a contigs.fa file as output.  

## busco
Output is in the **/mhannaert/test_illuminapipelin/05_busco_test**

https://currentprotocols.onlinelibrary.wiley.com/doi/epdf/10.1002/cpz1.323 

I installed this as a conda environment.  

This is that the WSL is not strong enoug for this program, so I preformed it on the server.



## BV-BRC
Output is in the **/mhannaert/test_illuminapipelin/06_BVBRC_test**

Installed in WSL  

Following tutorials:
 https://www.youtube.com/watch?v=7vpkY6LVYds&list=PLWfOyhOW_OauPk1470V1KUwOlyHzAarok&index=18 

https://youtu.be/97WpQfUW1uI?feature=shared 

## anvio 
I followed these workflows and made the exercises:

https://merenlab.org/2017/12/11/additional-data-tables/  
https://merenlab.org/tutorials/vibrio-jasicida-pangenome/  
https://howtoscience95037094.wordpress.com/2018/05/23/how-to-conduct-a-pangenome-analysis-using-anvio/  

all the output is in the **/mhannaert/test_illuminapipelin/07_anvio**

I checked the information in the scripts from steve, these can be found in the /scripts directory
script anvi-reformat-fasta.sh:

https://anvio.org/help/main/programs/anvi-script-reformat-fasta/ 

script anvio_gen_contigs_db.sh:

https://anvio.org/help/7/programs/anvi-gen-contigs-database/ -> Generate a new anvi'o contigs database.

https://anvio.org/help/7/programs/anvi-run-ncbi-cogs/ -> This program runs NCBI's COGs to associate genes in an anvi'o contigs database with functions. COGs database was been designed as an attempt to classify proteins from completely sequenced genomes on the basis of the orthology concept..

https://anvio.org/help/7/programs/anvi-run-hmms/ -> This program deals with populating tables that store HMM hits in an anvi'o contigs database.
-just-do-it option: to hide all warnings and questions in case you don’t want to deal with those.

https://anvio.org/help/7/programs/anvi-run-scg-taxonomy/ -> The purpose of this program is to affiliate single-copy core genes in an anvi'o contigs database with taxonomic names. A properly setup local SCG taxonomy database is required for this program to perform properly. After its successful run, anvi-estimate-scg-taxonomy will be useful to estimate taxonomy at genome-, collection-, or metagenome-level.

https://anvio.org/help/main/programs/anvi-scan-trnas/ -> Identify and store tRNA genes in a contigs database.

https://anvio.org/help/7/programs/anvi-run-kegg-kofams/ -> Run KOfam HMMs on an anvi'o contigs database. 

To display the contigs report:
````
anvi-display-contigs-stats *.db \
--report-as-text \
-o contig_db_report.txt
````
To generate contigs database: 
````
anvi-script-gen-genomes-file --input-dir . -o external-genomes.txt
anvi-gen-genomes-storage -e external-genomes.txt -o GENOMES.db
````
enerate profile DB for pangenome analysis:
````
anvi-pan-genome -g GENOMES.db --project-name pangenome_test --num-threads 32 
--exclude-partial-gene-calls
````
Add ANI to order the genomes:
````
anvi-compute-genome-similarity --external-genomes external-genomes.txt --program 
fastANI --output-dir ANI --num-threads 32 --pan-db pangenome_test /PAN.db
````

Add metadata (optional, but necessary for enrichment analysis):
````
anvi-import-misc-data additional_layers.txt \
-p pangenome_test /PAN.db \
--target-data-table layers
````
To visualize:
````
anvi-display-pan -g GENOMES.db \
-p pangenome_test /PAN.db
````
Select good SCG’s and make a cgMLST tree (Open treefile in FigTree or iTo):
````
anvi-get-sequences-for-gene-clusters -p pangenome_test /PAN.db \
-g GENOMES.db \
-C core -b core_99 \
--concatenate-gene-clusters \
-o SCG.fa

mafft --auto --reorder --thread 32 SCG.fa > SCG_mafft
iqtree2 -s SCG_mafft -T AUTO –B 1000`
````
Enrichment analysis:
````
anvi-compute-functional-enrichment-in-pan -p 
pangenome_test/PAN.db -g GENOMES.db -o 
functional-enrichment.txt --category-variable host --
annotation-source KEGG_Module
````
Export pangenome data/gene clusters with AA sequences to HTML and text:
````
anvi-summarize -p PROJECT-PAN.db -g PROJECT-PAN-GENOMES.db
-COLLECTION_NAME -o PROJECT-SUMMARY
````
