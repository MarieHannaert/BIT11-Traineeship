# Variant Calling 
For the last two weeks of my internship I will take a look at variant calling. I will start by the tool of SNIPPY and do visualisations in IGV. 

This is the mail I got:
````
Nu je de primaire analyse pipelines achter de rug hebt, kunnen we aan de slag met de gegenereerde data.

We beginnen eerst met Snippy (zie artikel op Mendeley), de standaard bacterial variant caller ( op genomics server : mamba activate snippy.)

Zie https://github.com/tseemann/snippy
Lees goed alle documentatie en zoek op waar je meer info over wil (VCF formaat, mapping quality, Freebayes, Gubbins)
Output van snippy-multi in /home/genomics/sbaeyen/SourceTrack/08_snippy, gemapte data = illumina data na fastp.
Opdracht :
visualiseer snps van de genomen van /home/genomics/sbaeyen/SourceTrack/08_snippy/batch1_selectie_aardappel in IGV adhv de VCF’s.
Welk soort varianten zijn hoofdzakelijk verantwoordelijk de differentiële snps in de gubbins boom?
Tip : referentie is GBBC502_reference.gbk in de bovenliggende map. In elke subfolder vind je interessante info:
snps.bam
snps.vcf
je kunt de vcf files combineren tot een multisample vcf 😉
IGV tutorials volgen hiervoor: https://www.youtube.com/@IGVtutorials/videos, probeer navigatie en visualisatie van SNPs, vcf en bam files.
Snippy staat op de server, enkel Gubbins zal je op je WSL moeten doen (staat niet op de server) als we een boom zn matrix willen maken voor bvb. figtree (http://tree.bio.ed.ac.uk/software/figtree/ )/ggtree -> zie howto file
````
## Snippy documentation 
https://github.com/tseemann/snippy/tree/master

I also took a look at the howto file 
````
Snippy v4.6.0


https://github.com/tseemann/snippy
The Snippy manual is at http://github.com/tseemann/snippy/blob/master/README.md

install on WSL20

conda install -c conda-forge -c bioconda -c defaults snippy

snippy --cpus 16 --outdir mysnps --ref Listeria.gbk --R1 FDA_R1.fastq.gz --R2 FDA_R2.fastq.gz

on genomics2

https://hub.docker.com/r/staphb/snippy

make a file input.tab ([ID] path/to_file1 path/to_file1)

LMG9576	/data/070_001_200214_001_0117_037_01_1841_1.fq.gz	/data/070_001_200214_001_0117_037_01_1841_2.fq.gz
GBBC513	/data/070_001_200804_001_0123_037_01_1851_1.fq.gz	/data/070_001_200804_001_0123_037_01_1851_2.fq.gz
GBBC522	/data/070_001_200804_001_0124_037_01_1851_1.fq.gz	/data/070_001_200804_001_0124_037_01_1851_2.fq.gz
GBBC655	/data/070_001_200804_001_0126_037_01_1851_1.fq.gz	/data/070_001_200804_001_0126_037_01_1851_2.fq.gz
GBBC3044	/data/070_001_200804_001_0127_037_01_1851_1.fq.gz	/data/070_001_200804_001_0127_037_01_1851_2.fq.gz
GBBC3360	/data/070_001_200804_001_0128_037_01_1851_1.fq.gz	/data/070_001_200804_001_0128_037_01_1851_2.fq.gz


docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/<name-of-docker-image>:<tag> <command> <--flags --go --here>

# example:
docker run --rm=True -v $PWD:/data staphb/snippy \
    snippy-multi input.tab --ref /data/LMG9576.fasta --cpus 48 > runme.sh
	
docker run --rm=True -v $PWD:/data staphb/snippy sh ./runme.sh

docker run --rm=True -v $PWD:/data staphb/snippy \ 
	snippy-clean_full_aln core.full.aln > clean.full.aln
% run_gubbins.py -p gubbins clean.full.aln op WSL (installed via conda), copy gubbins.filtered_polymorphic_sites.fasta file terug naar genomics2
docker run --rm -it -v $PWD:/data sangerpathogens/snp-sites snp-sites -c /data/gubbins.filtered_polymorphic_sites.fasta > clean.core.aln
% FastTree -gtr -nt clean.core.aln > clean.core.tree en open in figtree.
````
## More information
**VCF formaat** Variant Call Format, https://www.ebi.ac.uk/training/online/courses/human-genetic-variation-introduction/variant-identification-and-analysis/understanding-vcf-format/
>VCF is the standard file format for storing variation data. It is used by large scale variant mapping projects such as IGSR. It is also the standard output of variant calling software such as GATK and the standard input for variant analysis tools such as the VEP or for variation archives like EVA.\
VCF is a preferred format because it is unambiguous, scalable and flexible, allowing extra information to be added to the info field. Many millions of variants can be stored in a single VCF file. 

Column Content Description

 **#CHROM**-Chromosome\
 **POS**-Co-ordinate - The start coordinate of the variant.\
 **ID**-Identifier\
 **REF**-Reference allele - The reference allele is whatever is found in the reference genome. It is not necessarily the major allele.\
 **ALT**-Alternative allele - The alternative allele is the allele found in the sample you are studying.\
 **QUAL**-Score - Quality score out of 100.\
 **FILTER**-Pass/fail - If it passed quality filters.\
 **INFO**-Further information - Allows you to provide further information on the variants. Keys in the INFO field can be defined in header lines above the table.\
 **FORMAT**-Information about the following columns - The GT in the FORMAT column tells us to expect genotypes in the following columns.\
 **NA1999**-Individual identifier (optional) - The previous column told us to expect to see genotypes here. The genotype is in the form 0|1, where 0 indicates the reference allele and 1 indicates the alternative allele, i.e it is heterozygous. The vertical pipe | indicates that the genotype is phased, and is used to indicate which chromosome the alleles are on. If this is a slash / rather than a vertical pipe, it means we don’t know which chromosome they are on.

**mapping quality** Mapping Quality Scores quantify the probability that a read is misplaced
https://bactopia.github.io/v3.0.0/bactopia-tools/snippy/#output-overview

**Freebayes**
>freebayes is a Bayesian genetic variant detector designed to find small polymorphisms, specifically SNPs (single-nucleotide polymorphisms), indels (insertions and deletions), MNPs (multi-nucleotide polymorphisms), and complex events (composite insertion and substitution events) smaller than the length of a short-read sequencing alignment.\
freebayes is haplotype-based, in the sense that it calls variants based on the literal sequences of reads aligned to a particular target, not their precise alignment. This model is a straightforward generalization of previous ones (e.g. PolyBayes, samtools, GATK) which detect or report variants based on alignments. This method avoids one of the core problems with alignment-based variant detection--- that identical sequences may have multiple possible alignments.\
freebayes uses short-read alignments (BAM files with Phred+33 encoded quality scores, now standard) for any number of individuals from a population and a reference genome (in FASTA format) to determine the most-likely combination of genotypes for the population at each position in the reference. It reports positions which it finds putatively polymorphic in variant call file (VCF) format. It can also use an input set of variants (VCF) as a source of prior information, and a copy number variant map (BED) to define non-uniform ploidy variation across the samples under analysis.

https://github.com/freebayes/freebayes

**Gubbins**
Genealogies Unbiased By recomBinations In Nucleotide Sequences

>Gubbins (Genealogies Unbiased By recomBinations In Nucleotide Sequences) is an algorithm that iteratively identifies loci containing elevated densities of base substitutions, which are marked as recombinations, while concurrently constructing a phylogeny based on the putative point mutations outside of these regions. Simulations demonstrate the algorithm generates highly accurate reconstructions under realistic models of short-term bacterial evolution, and can be run in only a few hours on alignments of hundreds of bacterial genome sequences.

https://github.com/nickjcroucher/gubbins

## Output Snippy
I went looking for the output of the snippy tool. 
When I went to the directory my supervisor shared and selected on "Snippy" I got the following output: 
````
240503_Snippy_boom_selectie.pdf
240503_SourceTrack_Snippy2.pdf
240503_SourceTrack_Snippy.pdf
240503_SourceTrack_Snippy.svg
````

The documentation shows that the output would be:\
**.aln**	A core SNP alignment in the --aformat format (default FASTA)\
**.full.aln**	A whole genome SNP alignment (includes invariant sites)\
**.tab**	Tab-separated columnar list of core SNP sites with alleles but NO annotations\
**.vcf**	Multi-sample VCF file with genotype GT tags for all discovered alleles\
**.txt**	Tab-separated columnar list of alignment/core-size statistics\
**.ref.fa**	FASTA version/copy of the --ref\
**.self_mask.bed**	BED file generated if --mask auto is used.

For using IGV I need as input the ".vcf" files. 

## Tutorials IGV
I needed to take a look at the following tutorials for IGV:  https://www.youtube.com/@IGVtutorials/videos

specialy the ones about: 
- navigation SNP's 
- visualisation SNP's
- VCF files 
- Bam files 

### VCF files 
https://youtu.be/EpD2ZHM7Q8Q

VCF only stores variants 

three parts: 
- Meta-information 
-Header
- varaints 

Information about the file type, like I already described above. 
you have allel count and allel frequebncy, the frequency is how ofte the alternative occures. 

### IGV Desktop video list 
after following this video I decided the take a look at alle the video's because I think it's handy to know what IGV can do in general. 
All the seven videos are around 5min, so this won't take to long. 
The most interesting think to do is open IGV and following along with the tutorials, so that's what I did in this part. 

The BAI file is the index file. If this file isn't there, it won't load. So you need to have and .bam and .bai file. 

-> a reference is colored when it difference more than 20% from the reference. 
You can change this percentage. 

When you check SNP it's import to also take a look at the strand direction, because if all the snp are in a reverse strand then it will prob be false positive. 

By vcf if grey then its reference, if it's dark blue it's heterozygote variant, if it's light blue is homozygote variant. 

The last vieo was the most interessting for using: https://youtu.be/ZKwm8dqIQpg

## making a summary file of vcf
I need to make a multiple vcf file of all the vcf files. 
I need the snps.vcf files. 

I want to merge, the following information, but from different files: 
````
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	GBBC_504
cluster_001_consensus_polypolish	1830892	.	A	G	9161.09	.	AB=0;AO=259;DP=259;QA=10248;QR=0;RO=0;TYPE=snp	GT:DP:RO:QR:AO:QA:GL	1/1:259:0:0:259:10248:-921.735,-77.9668,0
cluster_001_consensus_polypolish	2592524	.	T	C	10228.4	.	AB=0;AO=295;DP=295;QA=11438;QR=0;RO=0;TYPE=snp	GT:DP:RO:QR:AO:QA:GL	1/1:295:0:0:295:11438:-1028.75,-88.8039,0
cluster_001_consensus_polypolish	2902857	.	C	T	10138.5	.	AB=0;AO=288;DP=288;QA=11323;QR=0;RO=0;TYPE=snp	GT:DP:RO:QR:AO:QA:GL	1/1:288:0:0:288:11323:-1018.39,-86.6966,0
````
I need to specify somewhere the sample, but the formats needs to be right. 
I will fist make two scripts and then discuss with my supervisor what he needs. 
first simple version that just combines all the files:
**/home/genomics/mhannaert/scripts/summary_vcf.sh**
content: 
````
#!/bin/bash
# This script will create a muliple vcf file 

DIR="$1"
OUT="$(pwd)"
cd "$DIR"

touch multiple_vcf.vcf

for file in $(find -type f -name "snps.vcf"); do
    cat "$DIR"/"$file" >> "$OUT"/multiple_vcf.vcf
done
````

I tried this mini script: it worked, everything was just put below eachother

Now I want to make a script that only uses these few last lines of the file. 

This is what I made in **/home/genomics/mhannaert/scripts/summary_vcf_lines.sh**
````
#!/bin/bash
# This script will create a muliple vcf file with only the last lines of the VCF files. 

DIR="$1"
OUT="$(pwd)"
cd "$DIR"

touch "$OUT"/multiple_vcf.vcf

for sample in $(ls -d); do
    grep -v '^##' "$sample"/snps.vcf >> "$OUT"/multiple_vcf.vcf
done
````
I treid this: 
Didn't work

I changed the following line: 
````
    cat "$sample"/snps.vcf | grep -v '^##'  >> "$OUT"/multiple_vcf.vcf
````
Didn't work either, problem is with the directory. 
I add the following: 
````
for sample in $(ls -d "$DIR"/*)
````
Did work. the summary was made. 

## asked my supervisor 
I asked about the scripts and he told we need the one without all the metadata. so: **/home/genomics/mhannaert/scripts/summary_vcf_lines.sh**

Also there are some samples double, so he asked to check wheter the SNP that are present are the same or if there are big differences. 

## trying IGV with my own multifile 
I took the file that steve told me as reference genome. 
But I don't know if that's the right one. 
I treid to load in the data in IGV, but got the following error: 
>Error loading \\192.168.236.131\genomics\mhannaert\multiple_vcf_lines.vcf: Unable to parse header with error: Your input file has a malformed header: We never saw a header line specifying VCF version, for input source: \\192.168.236.131\genomics\mhannaert\multiple_vcf_lines.vcf

I think it becaus the file does miss some of the metadata that is needed to load in. 
So I used the summary file with all the metadata from the first script and this gives a bit of a result. 
But still not the same as in the tutorial. 

I decided not to work anymore with a multi file, but make a directory with all the needed files and load these in at the same time. 

I made tree directories with the files I need for IGV: 
- **/home/genomics/mhannaert/variant_calling/bam_bai_IGV**
- **/home/genomics/mhannaert/variant_calling/snps_IGV**
- **/home/genomics/mhannaert/variant_calling/bam_IGV**

I now tried IGV again, 
I also copied the reference to my varaint calling directory:
**/home/genomics/mhannaert/variant_calling/GBBC502_reference.gbk**

Oke after rewatching again I need to remake my script for mulitple I now know why It's not working. 
so I changed it to: 

````
#!/bin/bash
# This script will create a muliple vcf file with only the last lines of the VCF files. 

DIR="$1"
OUT="$(pwd)"
cd "$DIR"

touch "$OUT"/multiple_vcf_lines.vcf

sample_list=()
for file in $(ls | grep "GBBC");
do sample_list+=("$file");
done
echo $sample_list
echo -e "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t$sample_list" >> "$OUT"/multiple_vcf_lines.vcf

for sample in $(ls | grep "GBBC"); do
    cat "$sample"/snps.vcf | grep -v '^#'  >> "$OUT"/multiple_vcf_lines.vcf
done
````
but I only get one sample name as output. 

I made it like this: 
````
#!/bin/bash
# This script will create a muliple vcf file with only the last lines of the VCF files. 

DIR="$1"
OUT="$(pwd)"
cd "$DIR"

touch "$OUT"/multiple_vcf_lines.vcf

sample_list=$(ls | grep "GBBC_")
echo $sample_list

echo -e "##fileformat=VCFv4.2" >> "$OUT"/multiple_vcf_lines.vcf
echo -e "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t$sample_list" >> "$OUT"/multiple_vcf_lines.vcf

for sample in $(ls | grep "GBBC_"); do
    cat "$sample"/snps.vcf | grep -v '^#'  >> "$OUT"/multiple_vcf_lines.vcf
done
````
But when i load it in: 
>Error loading \\192.168.236.131\genomics\mhannaert\variant_calling\multiple_vcf_lines.vcf: Line 2: there aren't enough columns for line GBBC_1291_B (we expected 9 tokens, and saw 1 ), for input source: \\192.168.236.131\genomics\mhannaert\variant_calling\multiple_vcf_lines.vcf

So still something wrong with my file: 
The sample names are now below eachother, but they need to be one line 
I did this by hand, but still wasn't right: 
>Error loading \\192.168.236.131\genomics\mhannaert\variant_calling\multiple_vcf_lines.vcf: The provided VCF file is malformed at approximately line number 3: there are 1 genotypes while the header requires that 43 genotypes be present for all records at cluster_001_consensus_polypolish:829567, for input source: \\192.168.236.131\genomics\mhannaert\variant_calling\multiple_vcf_lines.vcf

Because I only have one genotype....
So I think qua structure the file is correct, but there is missing some information 
Okay maybe it is not correct. 
Because what stands next to format are the genotypes, but I put my sample names there, so that is not correct. 

So I will go back to the previous version of the script. 

````
#!/bin/bash
# This script will create a muliple vcf file with only the last lines of the VCF files. 

DIR="$1"
OUT="$(pwd)"
cd "$DIR"

touch "$OUT"/multiple_vcf_lines.vcf

echo -e "##fileformat=VCFv4.2" >> "$OUT"/multiple_vcf_lines.vcf
echo -e "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT" >> "$OUT"/multiple_vcf_lines.vcf

for sample in $(ls | grep "GBBC_"); do
    cat "$sample"/snps.vcf | grep -v '^#'  >> "$OUT"/multiple_vcf_lines.vcf
done
````
this gave also an error: 
>Error loading \\192.168.236.131\genomics\mhannaert\variant_calling\multiple_vcf_lines.vcf: Unable to parse header with error: Your input file has a malformed header: The FORMAT field was provided but there is no genotype/sample data, for input source: \\192.168.236.131\genomics\mhannaert\variant_calling\multiple_vcf_lines.vcf

I removed the "FORMAT",
This gave the following error: 
>Error loading \\192.168.236.131\genomics\mhannaert\variant_calling\multiple_vcf_lines.vcf: The provided VCF file is malformed at approximately line number 3: The VCF specification does not allow for whitespace in the INFO field. Offending field value was "AB=0;AO=233;DP=233;QA=9297;QR=0;RO=0;TYPE=snp GT:DP:RO:QR:AO:QA:GL 1/1:233:0:0:233:9297:-836.229,-70.14,0", for input source: \\192.168.236.131\genomics\mhannaert\variant_calling\multiple_vcf_lines.vcf

I discussed all the things above with my supervisor and he told me I was right when I said that I missed some information in the files, like the genotypes, and that indeed thats the reason why it's not working. 

So he will take a look at it and I can leave it for now. 
And that I can do other things

## Trying Gubbins
If I want to try this, I need to do this in my WSL told my supervisor. 

I also need to install this first in my WSL. 
````
conda install gubbins
````
It is isntalled in my conda base in mijn WSL

I talked with my supervisor about this, he showed me how he did it and wich steps he took 

So I think it's a good idea I do all these steps myself. 
To perfomr these steps I need the data after running fasp. 

## Snippy-gubbins 
So I started by running fastp on my data that I got in **/home/genomics/mhannaert/data/00_reads**

first I changed bz2 to gz
Now I will perform fastp on the gz files: 
the result can be found **/home/genomics/mhannaert/data/after_fastp**

### further Snippy 
I will now run snippy on these fasp samples. 

I made an input.tab file of all the samples: 
**/home/genomics/mhannaert/variant_calling/input.tab**
I runned the following command: 
````
snippy-multi /home/genomics/mhannaert/variant_calling/input.tab --ref /home/genomics/mhannaert/variant_calling/GBBC502_reference.gbk --cpus 16 > runme.sh
````
But this gave an error: 
>Reading: input.tab
'RROR: [GBBC_1287] unreadable file '/home/genomics/mhannaert/data/after_fastp/GBBC_1287_2.fq.gz

My file was a windows file, thus we have changed the file in notepad ++ to a unix file. 

and a lot of typos

Now It worked. 
The script runme.sh was made. 
The following step is: 
sh ./runme.sh

The output is per sample a directory and some files, the interesting files for late rin gubbins are: 
- core.aln
- core.full.aln
- core.ref.fa
- core.tab
- core.txt
- core.vcf

So the next step with these files is perfoming the celan in snippy: 
>You can remove all the "weird" characters and replace them with N using the included snippy-clean_full_aln. This is useful when you need to pass it to a tree-building or recombination-removal tool

So I perfomed the following command: 
````
snippy-clean_full_aln core.full.aln > clean.full.aln
````
this created thus a clean.full.aln

with this file I can work with gubbins 
### Gubbins 
Like I said before Gubbins needs to be perfomed in my WSL. 

This is what stands in the snippy documentation for gubbins: 
````
run_gubbins.py -p gubbins clean.full.aln
````
I went now first looking again at the gubbins documentation and there the command is the same so I will now run this command. 
The output from this is: 
- gubbins.final_tree.tre 
- gubbins.log
- gubbins.node_labelled.final_tree.tre
- gubbins.per_branch_statistics.csv
- gubbins.recombination_predictions.embl
- gubbins.recombination_predictions.gff
- gubbins.summary_of_snp_distribution.vcf
- gubbins.branch_base_reconstruction.embl
- gubbins.filtered_polymorphic_sites.fasta
- gubbins.filtered_polymorphic_sites.phylip 

## ggtree
Now with the files I got from the gubbins I kan take a look at the tree in ggtree for getting a nice tree. 

The file I need to do this is the **gubbins.node_labelled.final_tree.tre** 

I only need to find out how to use this data in Rstudio, because ggtree is from Rstudio. 

This file I need to read in is a newick format
I found online that I need: 
````
ape::read.tree(filename); phytools::read.newick(filename)
````
I also found this interesting information for in the end:
>To save a tree to a text file, use ape::write.tree(tree, file='filename.txt') for Newick format (widely supported by most phylogenetic software)

to read in the file: 
````
tree1 <- ape::read.tree("/home/genomics/mhannaert/variant_calling/Gubbins/gubbins.node_labelled.final_tree.tre"); 
tree2 <- phytools::read.newick("/home/genomics/mhannaert/variant_calling/Gubbins/gubbins.node_labelled.final_tree.tre")
````
The output is then: 
````
> ape::read.tree("/home/genomics/mhannaert/variant_calling/Gubbins/gubbins.node_labelled.final_tree.tre"); 

Phylogenetic tree with 29 tips and 28 internal nodes.

Tip labels:
  GBBC_762, GBBC_767_2, GBBC_629, GBBC_3519, GBBC_1317, GBBC_632, ...
Node labels:
  Node_28, Node_13, Node_12, Node_10, Node_9, Node_2, ...

Rooted; includes branch lengths.
> phytools::read.newick("/home/genomics/mhannaert/variant_calling/Gubbins/gubbins.node_labelled.final_tree.tre")
Read 1 item
````
interesting site: https://eeob-macroevolution.github.io/Practicals/Intro_to_Phylo/intro_to_phylo.html

I first need to install ggtree. 
It was already installed. 

SO now I will try to visualise a simple tree. 

these are all the sort of styles of trees you can make: 
````
library(ggtree)
ggtree(tree1)

ggtree(tree1, layout="slanted") 
ggtree(tree1, layout="circular")
ggtree(tree1, layout="fan", open.angle=120)
ggtree(tree1, layout="equal_angle")
ggtree(tree1, layout="daylight")
ggtree(tree1, branch.length='none')
ggtree(tree1, branch.length='none', layout='circular')
ggtree(tree1, layout="daylight", branch.length = 'none')
````
I will now try to make the visualisation better
````
ggtree(tree1, mrsd="2021-01-01")+ theme_tree2()

ggtree(tree1,  mrsd="2023-01-01")+ geom_tiplab()+ theme_tree2()
````
But it isn't correct with the date, for expample sample 683 is taken in 1999, but in my tree it is 2018, so I need to specify thing more. 

All the things I try come from: https://guangchuangyu.github.io/ggtree-book/chapter-ggtree.html#methods-and-materials-1
