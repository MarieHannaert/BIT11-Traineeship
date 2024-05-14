# Test long read pipeline
This pipeline will work on data that comes from the minion or nanopore 

## data
The data to test this pipeline can be found in: 
/home/genomics/mhannaert/test_longreadpipeline/GBBC504

## pod5
https://github.com/nanoporetech/pod5-file-format

"POD5 is a file format for storing nanopore dna data in an easily accessible way. The format is able to be written in a streaming manner which allows a sequencing instrument to directly write the format." 

https://pod5-file-format.readthedocs.io/en/latest/

To get to the POD5 you need to be on the minion_pc: 
There I got my own folder if I want to save my data. 

I didn't understand the pod5 quit well, so I asked again: 
This is thus just a file format with raw data from a nanoporerun
sush a file contains each time 4000sequences. 


## Dorado 
from this tool is I first looked at the howto file of Steve. 

https://github.com/nanoporetech/dorado
https://community.nanoporetech.com/posts/research-release-basecall

"Dorado is a high-performance, easy-to-use, open source basecaller for Oxford Nanopore reads."

-> this is already performed on the data in the directory, so I won't do it again 

the command that is used: 
````
time dorado basecaller dna_r10.4.1_e8.2_400bps_sup@v4.3.0 ./barcode13/ --emit-fastq > ./barcode13.fq

for barcode in `ls barcode* -d`; do time dorado basecaller /opt/ont/rerio/dorado_models/res_dna_r10.4.1_e8.2_400bps_sup@2023-09-22_bacterial-methylation ./"$barcode"/ --emit-fastq > ./"$barcode".fq ; done
````
dorado basecaller will attempt to detect any adapter or primer sequences at the beginning and ending of reads, and remove them from the output sequence.

By default, Dorado is set up to trim the barcode from the reads. To disable trimming, add --no-trim to the cmdline.

The default heuristic for double-ended barcodes is to look for them on either end of the read. This results in a higher classification rate but can also result in a higher false positive count. To address this, dorado basecaller also provides a --barcode-both-ends option to force double-ended barcodes to be detected on both ends before classification. This will reduce false positives dramatically, but also lower overall classification rates.

## Nanoplot  
https://github.com/wdecoster/NanoPlot
This is a mamba enviroment 

  -t, --threads THREADS Set the allowed number of threads to be used by the script


I tried to perform this: 

````
mamba activate nanoplot 
NanoPlot -t 2 --fastq reads1.fastq.gz reads2.fastq.gz --maxlength 40000 --plots hex dot

output: 
WARNING: hex as part of --plots has been deprecated and will be ignored. To get the hex output, rerun with --legacy hex.

````
So that isn't completly correct, so I tried the following command: 
````
NanoPlot -t 2 --fastq GBBC50*/*.fq.gz --maxlength 40000 --plots --legacy hex dot

output: 
NanoPlot needs seaborn and matplotlib with --legacy
````
So again something wrong

this command worked

--maxlength N         Hide reads longer than length specified.

--plots               Specify which bivariate plots have to be made.
                        One or more of 'dot' (default), 'kde' (default), 'hex' and 'pauvre'

    
````
NanoPlot -t 2 --fastq GBBC50*/*.fq.gz --maxlength 40000 --plots --legacy hex dot
````
I got output, these can be found in: 
**/home/genomics/mhannaert/test_longreadpipeline/output_nanoplot**
here there are multiple plots that were made, some html and some log files. 

## Filtlong  
https://github.com/rrwick/Filtlong

Filtlong is a tool for filtering long reads by quality. It can take a set of long reads and produce a smaller, better subset. It uses both read length (longer is better) and read identity (higher is better) when choosing which reads pass the filter.

I runned following command in **/home/genomics/mhannaert/test_longreadpipeline**, I did this in a tmux session:

````
for sample in `ls GBBC50*/*.fq.gz | awk 'BEGIN{FS=".fq.gz"}{print $1}'`; do filtlong --min_length 1000 --target_bases 540000000 "$sample".fq.gz |  gzip > ./"$sample"_1000bp_100X.fq.gz ; done
````
It worked only that in the GBBC504 all these files already available were. because I got the following commant: 
````
-bash: ./GBBC504/GBBC_504_sup_1000bp_100X.fq.gz: cannot overwrite existing file
````

## Porechop_ABI 
https://github.com/bonsai-team/Porechop_ABI

"Porechop_ABI (ab initio) is an extension of Porechop whose purpose is to process adapter sequences in ONT reads.

The difference with the initial version of Porechop is that Porechop_ABI does not use any external knowledge or database for the adapters. Adapters are discovered directly from the reads using approximate k-mers counting and assembly. Then these sequences can be used for trimming, using all standard Porechop options.

The software is able to report a combination of distinct sequences if a mix of adapters is used. It can also be used to check whether a dataset has already been trimmed out or not, or to find leftover adapters in datasets that have been previously processed with Guppy.

Note that Porechop_ABI is not designed to handle barcoded sequences adapters. Demultiplexing should be done using standard Porechop commands or other appropriate tools."

This is installed on the server in a mamba env: porechop_abi 
 this can be executed in a one line command, for example: 
 ````
 for sample in `ls *.fq | awk 'BEGIN{FS=".fq"}{print $1}'`; do porechop_abi -abi -t 32 -v 2 -i $sample.fq -o "$sample"_trimmed.fq ; done
 ````

 I tried this on my own test data in: **/home/genomics/mhannaert/test_longreadpipeline**:
 ````
 mamba activate porechop_abi
for sample in `ls GBBC50*/*.fq.gz | awk 'BEGIN{FS=".fq.gz"}{print $1}'`; do porechop_abi -abi -t 32 -v 2 -i $sample.fq.gz -o "$sample"_trimmed.fq.gz ; done | tee porechop_abi.log
 ````
 output **/home/genomics/mhannaert/test_longreadpipeline/porechop_abi.log**
The running of the script took some time
-> next time in a tmux session 
I stopped it because it was using more files than needed, because of the "*.fq.gz" I needed to specify it more. I changed the " * " to a " ? ". Because now it will only change to one character and not the files with multiple characters after te start of that name. 

````
for sample in `ls GBBC50*/GBBC50?.fq.gz | awk 'BEGIN{FS=".fq.gz"}{print $1}'`; do porechop_abi -abi -t 32 -v 2 -i $sample.fq.gz -o "$sample"_trimmed.fq.gz ; done  | tee porechop_abi.log
````
it makes a tmp directory it he directory where you're working in. 

This went well 
The result can be found in: **/home/genomics/mhannaert/test_longreadpipeline/GBBC50?/GBBC50?_trimmed.fq.gz**
This wasn't good because I first had to unzip all the files that I needed 
so I performed:
````
gunzip -k GBBC50?/GBBC50?.fq.gz
````
and repreformd the following command without the .gz :
````
for sample in `ls GBBC50?/GBBC50?.fq | awk 'BEGIN{FS=".fq"}{p
rint $1}'`; do porechop_abi -abi -t 32 -v 2 -i $sample.fq -o "$sample"_trimmed.fq ; done  | tee porechop_abi.log
````

This will give output files that are not .gz, so these can be reformated to .fasta and used for the following step. The output can be seen in the log file: **/home/genomics/mhannaert/test_longreadpipeline/porechop_abi.log**

## flye 
https://github.com/fenderglass/Flye/
"Flye is a de novo assembler for single-molecule sequencing reads, such as those produced by PacBio and Oxford Nanopore Technologies. It is designed for a wide range of datasets, from small bacterial projects to large mammalian-scale assemblies. The package represents a complete pipeline: it takes raw PacBio / ONT reads as input and outputs polished contigs. Flye also has a special mode for metagenome assembly.

Currently, Flye will produce collapsed assemblies of diploid genomes, represented by a single mosaic haplotype. To recover two phased haplotypes consider applying HapDup after the assembly."

This is a conda enviroment 
 example command: 
 ````
 mamba activate flye
 flye --asm-coverage 50 --nano-hq reads.fasta --out-dir out_nano --threads 32 --iterations --scaffold
 ````
Before I can perform this, I need to reformat the .fq.gz files to a .fasta file. 
I can do this by the next command: 
````
cat GBBC50?/GBBC50?_trimmed.fq | awk '{if(NR%4==1) {printf(">%s\n",substr($0,2));} else if(NR%4==2) print;}' > OUTPUT.fasta
````
There went something wrong in the previous part so I had to redo the steps for sample GBBC504 because the .fq.gz file was called an other name and thus not recognised while doing the previous steps. 


I tried the tool for my two test samples with the follwowing command: 
````
flye --asm-coverage 50 --nano-hq GBBC50?/OUTPUT.fasta --out-dir out_nano --threads 32 --iterations --scaffold
````
The option that are important here are:

-asm-covarage 50: reduced coverage for initial disjointig assembly 

-nano-hq: ONT high-quality reads: Guppy5+ SUP or Q20 (<5% error)

-iterations: number of polishing iterations, when not given number the default is 1 

-scaffold: enable scaffolding using graph

The output is some errors: 
````
#first error after running the command:
flye: error: argument -i/--iterations: expected one argument

#error after adding "1" in the command after iterations: 
flye: error: --asm-coverage option requires genome size estimate (--genome-size)

#error after adding the --genome-size:
flye: error: argument -g/--genome-size: expected one argument

# end command: 
flye --asm-coverage 50 --genome-size 2.6g --nano-hq GBBC50?/OUTPUT.fasta --out-dir out_nano --threads 32 --iterations 1 --scaffold | tee flye.log
````
This didn't give the correct output, It missed a loop in the command,so I tried again with the following command: 

````
for sample in `ls GBBC50*/*.fasta | awk 'BEGIN{FS=".fasta"}{print $1}'`; do flye --asm-coverage 50 --genome-size 2.6g --nano-hq "$sample".fasta --out-dir flye_out --threads 32 --iterations 1 --scaffold ; done
````
The genome size isn't correct, so I asked my supervisor the genome size, this apperently 5.4g 
````
for sample in `ls GBBC50*/*.fasta | awk 'BEGIN{FS="/OUTPUT.fasta"}{print $1}'`; do flye --asm-coverage 50 --genome-size 5.4g --nano-hq "$sample"/OUTPUT.fasta --out-dir flye_out_"$sample" --threads 32 --iterations 1 --scaffold ; done     
````
This worked. 

## Trycycler  
start tmux session

https://genomebiology.biomedcentral.com/articles/10.1186/s13059-021-02483-z

>While long-read sequencing allows for the complete assembly of bacterial genomes, long-read assemblies contain a variety of errors. Here, we present Trycycler, a tool which produces a consensus assembly from multiple input assemblies of the same genome. Benchmarking showed that Trycycler assemblies contained fewer errors than assemblies constructed with a single tool. Post-assembly polishing further reduced errors and Trycycler+polishing assemblies were the most accurate genomes in our study. As Trycycler requires manual intervention, its output is not deterministic. However, we demonstrated that multiple users converge on similar assemblies that are consistently more accurate than those produced by automated assembly tools.

https://github.com/rrwick/Trycycler

>Trycycler is a tool for generating consensus long-read assemblies for bacterial genomes. I.e. if you have multiple long-read assemblies for the same isolate, Trycycler can combine them into a single assembly that is better than any of your inputs.

To perform this: 
````
mamba activate trycycler

trycycler

output:
usage: trycycler [-h] [--version] {subsample,cluster,dotplot,reconcile,msa,partition,consensus} ...

 _______                               _
|__   __|                             | |
   | | _ __  _   _   ___  _   _   ___ | |  ___  _ __
   | || '__|| | | | / __|| | | | / __|| | / _ \| '__|
   | || |   | |_| || (__ | |_| || (__ | ||  __/| |
   |_||_|    \__, | \___| \__, | \___||_| \___||_|
              __/ |        __/ |
             |___/        |___/

Trycycler: a consensus long-read assembly tool
Commands:
  {subsample,cluster,dotplot,reconcile,msa,partition,consensus}
                                        subsample: subsample a long-read set
                                        cluster:   cluster contigs by similarity
                                        dotplot:   draw pairwise dotplots for a cluster
                                        reconcile: reconcile contig sequences
                                        msa:       multiple sequence alignment
                                        partition: partition reads by cluster
                                        consensus: derive a consensus sequence
Help:
  -h, --help                            Show this help message and exit
  --version                             Show program's version number and exit
````

## hybracter 
start tmux session 

https://github.com/gbouras13/hybracter

>hybracter is an automated long-read first bacterial genome assembly tool implemented in Snakemake using Snaketool.
hybracter is designed for assembling bacterial isolate genomes using a long read first assembly approach. It scales massively using the embarassingly parallel power of HPC and Snakemake profiles. It is designed for applications where you have isolates with Oxford Nanopore Technologies (ONT) long reads and optionally matched paired-end short reads for polishing.
hybracter is desined to straddle the fine line between being as fully feature-rich as possible with as much information as you need to decide upon the best assembly, while also being a one-line automated program. In other words, as awesome as Unicycler, but updated for 2023. Perfect for lazy people like myself.
hybracter is largely based off Ryan Wick's magnificent tutorial and associated paper. hybracter differs in that it adds some additional steps regarding targeted plasmid assembly with plassembler, contig reorientation with dnaapler and extra polishing and statistical summaries.
Note: if you have Pacbio reads, as of 2023, you can run hybracter long with --no_medaka to turn off polishing, and --flyeModel pacbio-hifi. You can also probably just run Flye or Dragonflye (or of course Trycyler ) and reorient the contigs with dnaapler without polishing. See Ryan Wick's blogpost for more details.

documentation can be found: https://hybracter.readthedocs.io/en/latest/

````
mamba activate hybracterENV


hybracter version 0.6.0



 _           _                    _            
| |__  _   _| |__  _ __ __ _  ___| |_ ___ _ __ 
| '_ \| | | | '_ \| '__/ _` |/ __| __/ _ \ '__|
| | | | |_| | |_) | | | (_| | (__| ||  __/ |   
|_| |_|\__, |_.__/|_|  \__,_|\___|\__\___|_|   
       |___/


Usage: hybracter [OPTIONS] COMMAND [ARGS]...

  For more options, run: hybracter command --help

Options:
  -h, --help  Show this message and exit.

Commands:
  install        Downloads and installs the plassembler database
  hybrid         Run hybracter with hybrid long and paired end short reads
  hybrid-single  Run hybracter hybrid on 1 isolate
  long           Run hybracter with only long reads
  long-single    Run hybracter long on 1 isolate
  test-hybrid    Test hybracter hybrid
  test-long      Test hybracter long
  config         Copy the system default config file
  citation       Print the citation(s) for hybracter
  version        Print the version for hybracter
````
