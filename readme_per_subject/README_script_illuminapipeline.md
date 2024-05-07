# Script complete Illuminapipeline 
In this script I will completely code the Illuminapipe line, so sthat it can easly be used to perform on multiple samples the complete pipeline. 
Also I will later base my snakemake pipeline on this script. 
## Design 
The parts that need to be in the script are the following:
- fastqc 
- fastp 
- shovill 
- quast 
- busco 
- BVBRC
- anvio 
first I will just add all the steps and make sure that there are correct input and correct output 
after that this works I will update the script with different features like a log files and parameters that can be given
## start of the script 
I created the script on the following location: **/home/genomics/mhannaert/scripts/complete_illuminapipeline.sh**
The script is added to the directory **/home/genomics/mhannaert/scripts** because then it is alway available to perform it. 
the first thing I added to the script is the following: 
````
#!/bin/bash
# This script will perform the complete illumina pipeline so that the pipeline can be perfomed on multiple samples and in one step 
#when this script is completed, it needs to become a snakemake pipeline
#This script is meant to be performed on the server
````
This is some information about the script I will make that if anyone later see this script it will understand it 
The second thing I will add is where to start 
````
#The first thing needed is input, this can be given in a parameter by the script 
DIR=$1
cd $DIR
````
This can be a parameter because it is the first input directory for the script and moving there. 
The following important thing is that all the files are in the correct format. 
The start code I have here for is for bz2 -> gz: 
````
pbzip2 -d -p32
pigz
````
I think it's interesting to check if it is bz2 format or already gz. 
when I combine everything I get the following code: 
````
if [[ $2 == "bz2" ]];
    then
        pbzip2 -d -p32 *fq.bz2 
        pigz *.fq
elif [[ $2 == "gz" ]];
    then
        continue
else
    echo "The compression type is not supported. Please use gz or bz2"
    exit 1
fi
````
I think it is interesting to directly put the parameter part in the beginning:
````
function usage(){
	errorString="Running this Kraken2 script requires 4 parameters:\n
    1. Path of the folder with fastq.gz files.\n
    2. Type of compression (gz or bz2)\n
    3. Number of threads to use.";

	echo -e ${errorString};
	exit 1;
}

if [ "$#" -ne 3 ]; then
	usage
fi
````

I also already put the loop for the input directory: 
````
while true; do
  echo "The given input directory is: $1"

  if [ -d "$1" ]; then
    echo "$1 exists."
    break
  else
    echo "$1 does not exist. Please enter a correct path:"
    read -r DIR
    if [ -d "$DIR" ]; then
      # If the user entered a valid directory path, use it instead of the original argument
      set -- "$DIR"
    fi
  fi
done
````
Now I will make an output file so that all the output that is created from this script will end up in there, I also decided to do it as a parameter because If you want to run it on multiple bashec then you can give the output a different name: 
````
mkdir -p $OUT
````

I also already made a log file, one because I have this code already made in the Kraken2.sh script and it easy to follow the proces when testing the script, so I added: 
````
#making a log file 
touch "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#adding the user of the script that day to the log file 
echo "The user of today is" $USER | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
# adding the versions of the tools that are used 
echo "the version that are used are:" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#I will fill this in while writing the script 
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#adding the command to the log file
echo "the command that was used is:"| tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "complete_illuminapipeline.sh" $1 $2 $3 $4 |tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "This was performed in the following directory: $START_DIR" |tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
echo "====================================================================" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
````
