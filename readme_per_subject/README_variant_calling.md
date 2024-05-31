# Variant Calling 
For the last two weeks of my internship I will take a look at variant calling. I will start by the tool of SNIPPY and do visualisations in IGV. 
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
