#!/bin/bash
##checking for parameters
function usage(){
	errorString="Running this Kraken2 script requires 3 parameters:\n
		1. Path of the folder with fastq.gz files.\n
		2. Path of the output folder.\n
        3. Type of compression (gz or bz2)\n
        4. Number of threads to use.\n";

	echo -e ${errorString};
	exit 1;
}
if [ "$#" -ne 4 ]; then
	usage
fi

##setting parameters
DIR=$1
OUT=$2
COMP=$3
##running Kraken2   
#going to the directory with the fastq.gz files
cd $DIR

#creating the output directory if it doesn't exist yet
mkdir -p $OUT

#specifying type of compression 
if $COMP == "gz"
then 
    zip = "--gzip-compressed"

    elif $COMP == "bz2"
    then
        zip = "--bzip2-compressed"
    fi
    
fi

#running Kraken2 on all the fastq.gz files
 
for sample in `ls *.fq.$3 | awk 'BEGIN{FS=".fq.*"}{print $1}'`
do

echo "Running Kraken2 on $sample"
kraken2 $zip "$sample".fq.$3 --db /home/genomics/bioinf_databases/kraken2/NCBI_nt_20230205/ --report "$OUT"/"$sample"_kraken2 --threads $4 --quick --memory-mapping

ktImportTaxonomy -t 5 -m 3 -o "$OUT"/"$sample"_krona.html "$OUT"/"$sample"_kraken2.report

done

echo "Finished running Kraken2 and Krona "





