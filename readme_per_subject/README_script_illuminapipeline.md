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
	errorString="Running this Illumina pipeline script requires 4 parameters:\n
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
## Adding fastqc step
In this step a fastqc needs to be performed on all the samples
when the fastqc is done there needs to be a multiqc 
The start code I have to perform a fastqc and multiqc is: 
````
fastqc -t 32 *.gz --extract -o outdir 
mamba activate multiqc 
multiqc .
````
The code can just be putted there in this way:
````
#performing fastqc on the gz smaples 
fastqc -t 32 *.gz --extract -o "$OUT"/fastqc
#activating the mamba env 
mamba activate multiqc 
#perfomring the multiqc on the fastqc samples
multiqc "$OUT"/fastqc
#deactivating the mamba env
mamba deactivate multiqc
````
## testing the script for the first part 
To execute the script from everywhere I need to first perform the following command in the directory: **/home/genomics/mhannaert/scripts**
````
chmod u+x complete_illuminapipeline.sh 
````
So that the script is executable 
now I went to the directory: **/home/genomics/mhannaert/script_illuminapipeline**
I will perform the following command: 
```
complete_illuminapipeline.sh 
``` 
This gave the following output: 
````
Running this Kraken2 script requires 4 parameters:
 1. Path of the folder with fastq.gz files.
 2. Name of the output folder.
 3. Type of compression (gz or bz2)
 4. Number of threads to use.
````
so that is correct 
I first changed pbzip2 -d to pbzip2 -dk because I want to keep my test data bz2, so I can test later again. 
now I did the following command: 
````
complete_illuminapipeline.sh /home/genomics/mhannaert/data/mini_testdata/bz2_files output_test1 bz2 4
````
There were some problems with the file format recognition, so I changed it to:
````
if [[ $2 == "bz2" ]];
    then
        pbzip2 -dk -p32 *fq.bz2 
        pigz *.fq
elif [[ $2 == "gz" ]];
    then
        continue
elif [[$2 != "bz2"]|[ $2 = "gz" ] ]
    then
        echo "The compression type is not supported. Please use gz or bz2"
        exit 1
fi
````
the script didn't work 
it the log file there can be found the following: 
````
The user of today is mhannaert
====================================================================
the version that are used are:
====================================================================
the command that was used is:
complete_illuminapipeline.sh /home/genomics/mhannaert/data/mini_testdata/bz2_files output_test1 bz2 4
This was performed in the following directory: /home/genomics/mhannaert/script_illuminapipeline
====================================================================
Performing fastqc
Specified output directory 'output_test1/fastqc' does not exist
Run 'mamba init' to be able to run mamba activate/deactivate
and start a new shell session. Or use conda to activate/deactivate.

performing multiqc
/home/genomics/mhannaert/scripts/complete_illuminapipeline.sh: line 89: multiqc: command not found
Run 'mamba init' to be able to run mamba activate/deactivate
and start a new shell session. Or use conda to activate/deactivate.
````
so there are some errors that need the to be fixed before I continue with the rest. 
the first error is that the files are not reformated from bz2 to gz, so I decided to out command the part after so I only can check how to make the part about gz/bz2 work. 

I had in my code $2 but thats the output folder, it must be $3, I retried and it worked. => error solved. I replaced this part to below the log file, so that this also can be logged. 
`````
echo "checking fileformat and reformat if needed" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
if [[ $3 == "bz2" ]]; then
    #decompress bz2
    echo "files are reformated to gz" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    pbzip2 -dk -p32 *fq.bz2 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    #compress to gz
    pigz *.fq
elif [[ $3 == "gz" ]]; then
    echo "files are gz, so that's fine" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    continue 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
elif [[ $3 != "gz" ]] | [[ $3 != "bz2" ]]; then
    echo "This is not a correct file format, it can only be gz or bz2" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    exit 1 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
fi
````
I also checked for gz:
````
The user of 2024-05-07_17-01 is: mhannaert
====================================================================
the version that are used are:
====================================================================
the command that was used is:
complete_illuminapipeline.sh /home/genomics/mhannaert/data/mini_testdata/gz_files/ output_test1 gz 4
This was performed in the following directory: /home/genomics/mhannaert/script_illuminapipeline
====================================================================
checking fileformat and reformat if needed
files are gz, so that's fine
````
I also check with the parameter "g" if that works: 
````
The user of 2024-05-07_16-59 is: mhannaert
====================================================================
the version that are used are:
====================================================================
the command that was used is:
complete_illuminapipeline.sh /home/genomics/mhannaert/data/mini_testdata/gz_files/ output_test1 g 4
This was performed in the following directory: /home/genomics/mhannaert/script_illuminapipeline
====================================================================
checking fileformat and reformat if needed
This is not a correct file format, it can only be gz or bz2
````
So I tested everything and can say that the script works for this part. 

The error that the fastqc directory doesn't exist, can be solved by adding this to the script: 
````
mkdir "$OUT"/fastqc
````
When I test this it works because I got the following output in my log file: 
````
Performing fastqc
Picked up _JAVA_OPTIONS: -Dlog4j2.formatMsgNoLookups=true
Started analysis of 070_001_240321_001_0355_099_01_4691_1.fq.gz
Started analysis of 070_001_240321_001_0355_099_01_4691_2.fq.gz
Started analysis of 070_001_240321_001_0356_099_01_4691_1.fq.gz
Started analysis of 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 5% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 5% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 5% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 5% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 10% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 10% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 15% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 15% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 10% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 10% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 20% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 20% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 15% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 25% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 25% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 15% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 30% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 30% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 20% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 35% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 35% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 20% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 40% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 40% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 25% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 25% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 45% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 45% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 30% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 50% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 50% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 30% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 55% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 55% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 35% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 60% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 60% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 35% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 65% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 65% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 40% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 70% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 70% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 40% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 75% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 75% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 45% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 80% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 80% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 45% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 85% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 50% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 85% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 50% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 90% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 90% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 55% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 95% complete for 070_001_240321_001_0356_099_01_4691_1.fq.gz
Approx 95% complete for 070_001_240321_001_0356_099_01_4691_2.fq.gz
Approx 55% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 60% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 60% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 65% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 65% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 70% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 70% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 75% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 75% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 80% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 80% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 85% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 85% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 90% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 90% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
Approx 95% complete for 070_001_240321_001_0355_099_01_4691_1.fq.gz
Approx 95% complete for 070_001_240321_001_0355_099_01_4691_2.fq.gz
````
But this is a bit too much output in my log file, so I will change this. 
I don't save the standerror anymore. 
now the output looks like this: 
````
The user of 2024-05-07_17-09 is: mhannaert
====================================================================
the version that are used are:
====================================================================
the command that was used is:
complete_illuminapipeline.sh /home/genomics/mhannaert/data/mini_testdata/gz_files/ output_test1 gz 4
This was performed in the following directory: /home/genomics/mhannaert/script_illuminapipeline
====================================================================
checking fileformat and reformat if needed
files are gz, so that's fine
Performing fastqc
````
So that part of the script does also work now. 

I uncommented the multiqc line and reperformed the script, the result: 
````
Performing fastqc
Run 'mamba init' to be able to run mamba activate/deactivate
and start a new shell session. Or use conda to activate/deactivate.

performing multiqc
/home/genomics/mhannaert/scripts/complete_illuminapipeline.sh: line 93: multiqc: command not found
Run 'mamba init' to be able to run mamba activate/deactivate
and start a new shell session. Or use conda to activate/deactivate.
````
The mamba init I solved by adding 
````
mamba init 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
mamba activate multiqc 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#perfomring the multiqc on the fastqc samples
echo performing multiqc | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
multiqc "$OUT"/fastqc 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
#deactivating the mamba env
mamba deactivate multiqc 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
````
This didn't work, but I same that the base of conda was activated, so I eactivated that one
and reperformd the script
the output in the terminal:
````
no change     /opt/miniforge3/condabin/conda
no change     /opt/miniforge3/bin/conda
no change     /opt/miniforge3/bin/conda-env
no change     /opt/miniforge3/bin/activate
no change     /opt/miniforge3/bin/deactivate
no change     /opt/miniforge3/etc/profile.d/conda.sh
no change     /opt/miniforge3/etc/fish/conf.d/conda.fish
no change     /opt/miniforge3/shell/condabin/Conda.psm1
no change     /opt/miniforge3/shell/condabin/conda-hook.ps1
no change     /opt/miniforge3/lib/python3.10/site-packages/xontrib/conda.xsh
no change     /opt/miniforge3/etc/profile.d/conda.csh
modified      /home/mhannaert/.bashrc

==> For changes to take effect, close and re-open your current shell. <==

Added mamba to /home/mhannaert/.bashrc

==> For changes to take effect, close and re-open your current shell. <==

performing multiqc
````
output in the logfile:
````
Run 'mamba init' to be able to run mamba activate/deactivate
and start a new shell session. Or use conda to activate/deactivate.

performing multiqc
/home/genomics/mhannaert/scripts/complete_illuminapipeline.sh: line 93: multiqc: command not found
Run 'mamba init' to be able to run mamba activate/deactivate
and start a new shell session. Or use conda to activate/deactivate.
````
