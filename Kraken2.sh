#!/bin/bash
##need to: mamba activate krona 
##checking for parameters
function usage(){
	errorString="Running this Kraken2 script requires 4 parameters:\n
		1. Path of the folder with fastq.gz files.\n
		2. Name of the output folder.\n
        3. Type of compression (gz or bz2)\n
        4. Number of threads to use.\n
        -> you also have to activate the following conda env: krona";

	echo -e ${errorString};
	exit 1;
}

if [ "$#" -ne 4 ]; then
	usage
fi

##setting parameters
DIR=$1
OUT=$2
START_DIR=$(pwd)
DATE_TIME=$(date '+%Y-%m-%d_%H-%M')

##running Kraken2   
#going to the directory with the fastq.gz files
cd $DIR

#creating the output directory if it doesn't exist yet
mkdir -p $OUT

#making a log file 
touch "$OUT"/"$DATE_TIME"_kraken2.log
#adding the user of the script that day to the log file 
echo "The user of today is" $USER | tee -a "$OUT"/"$DATE_TIME"_kraken2.log
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_kraken2.log
# adding the versions of the tools that are used 
echo "the version that are used are:" | tee -a "$OUT"/"$DATE_TIME"_kraken2.log
kraken2 -v | tee -a "$OUT"/"$DATE_TIME"_kraken2.log
mamba list | grep krona | tee -a "$OUT"/"$DATE_TIME"_kraken2.log  
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_kraken2.log
#adding the command to the log file
echo "the command that was used is:"| tee -a "$OUT"/"$DATE_TIME"_kraken2.log
echo "Kraken2.sh" $1 $2 $3 $4 |tee -a "$OUT"/"$DATE_TIME"_kraken2.log
echo "This was performd in the following directory: $START_DIR" |tee -a "$OUT"/"$DATE_TIME"_kraken2.log
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_kraken2.log
#specifying type of compression 
if $3 == "gz";
    then 
        zip = "--gzip-compressed"

elif $3 == "bz2";
    then
        zip = "--bzip2-compressed"
fi

#running Kraken2 on all the fastq.gz files
 
for sample in `ls *.fq.* | awk 'BEGIN{FS=".fq.*"}{print $1}'`
do
#running Kraken2 on each sample
echo "Running Kraken2 on $sample"
kraken2 $zip "$sample".fq.$3 --db /home/genomics/bioinf_databases/kraken2/Standard --report "$OUT"/"$sample"_kraken2.report --threads $4 --quick --memory-mapping 2>&1 |tee -a "$OUT"/"$DATE_TIME"_kraken2.log

#running Krona on the report
echo "Running Krona on $sample"
ktImportTaxonomy -t 5 -m 3 -o "$OUT"/"$sample"_krona.html "$OUT"/"$sample"_kraken2.report 2>&1 |tee -a "$OUT"/"$DATE_TIME"_kraken2.log

#removing the kraken reports after using these for krona
echo "Removing kraken2 report"
rm "$OUT"/"$sample"_kraken2.report 2>&1 |tee -a "$OUT"/"$DATE_TIME"_kraken2.log

done

echo "Finished running Kraken2 and Krona "





