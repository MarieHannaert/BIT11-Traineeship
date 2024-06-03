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