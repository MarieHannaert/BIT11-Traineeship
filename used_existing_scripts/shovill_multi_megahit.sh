#!/bin/bash
# (c) Steve Baeyen 2020
# steve.baeyen@ilvo.vlaanderen.be
# 
# Script to assemble a whole directory with Shovill v1.0.9 on the ILVO genomics2 server

# ask for the directory where the fastq files are

echo "Please provide the absolute path to the read directory:"
read DIR
cd $DIR

# store all files ending with _1.fq in the variable FILES
FILES=(*_1.fq.gz)

#loop over all files in $FILES and do the assembly for each of the files
for f in "${FILES[@]}" 
do 
	SAMPLE=`basename $f _1.fq.gz`  	#extract the basename from the file and store it in the variable SAMPLE

	#run Shovill
	shovill --R1 "$DIR"/"$SAMPLE"_1.fq.gz --R2 "$DIR"/"$SAMPLE"_2.fq.gz --assembler megahit --cpus 16 --ram 16 --minlen 500 --trim -outdir ../output_megahit/"$SAMPLE"/
	echo Assembly "$SAMPLE" done !
done
echo "*******************************************"
echo "All assemblies finished, have a nice day !"
echo "*******************************************"