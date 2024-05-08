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
````
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
## further solving error mamba 
I tried already different options
- use conda activate 
- source 

Now I changed the mamba to conda, because mamba is actually a layer on my conda, so conda will have more chance to work (advise of my supervisor)

result it didn't worked

now we added the following part to the top of the script: 
````
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
````
now it worked but just one error: 
````
ArgumentError: deactivate does not accept arguments
remainder_args: ['multiqc'] 
````
but that's because I added multiqc after, so now I removed it. 
The multiqc is added in the folder above, so I will make that the result of that is performed in the output folder that is defined
to fix this I will move in to the output folder. 
````
cd $OUT 
````
Also I want to remove the fastqc output once the multiqc is performed. So I added the following part:µ
````
rm -rd fastqc/ 
````
the -rd option means d for directory and r for recursive, so all the folders and files in that file too. 

result of running (content logfile): 
````
The user of 2024-05-08_09-34 is: mhannaert
====================================================================
the version that are used are:
====================================================================
the command that was used is:
complete_illuminapipeline.sh /home/genomics/mhannaert/data/mini_testdata/gz_files/ output_test2 gz 4
This was performed in the following directory: /home/genomics/mhannaert
====================================================================
checking fileformat and reformat if needed
files are gz, so that's fine
Performing fastqc
performing multiqc

  /// MultiQC 🔍 | v1.21

|           multiqc | Search path : /home/genomics/mhannaert/data/mini_testdata/gz_files/output_test2/fastqc
|         searching | ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100% 76/76  
|            fastqc | Found 4 reports
|           multiqc | Report      : multiqc_report.html
|           multiqc | Data        : multiqc_data
|           multiqc | MultiQC complete
removing fastqc/
````
This part of code that now works looks like this: 
````
conda activate multiqc 
#perfomring the multiqc on the fastqc samples
cd $OUT
echo performing multiqc | tee -a "$DATE_TIME"_Illuminapipeline.log
multiqc fastqc 2>> "$DATE_TIME"_Illuminapipeline.log
echo removing fastqc/ | tee -a "$DATE_TIME"_Illuminapipeline.log
rm -rd fastqc/ 2>> "$DATE_TIME"_Illuminapipeline.log
#deactivating the mamba env
conda deactivate
````
I will now add the version to the log file for the fastqc and the multiqc 
```
fastqc -v | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda activate multiqc
conda list | grep multiqc | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda deactivate
```
## Fastp
The part that needed to be added is the following, this is just only I you want to perform fastp on the command line: 
```
mkdir trimmed

#loop over read files

for g in `ls *_1.fq.gz | awk 'BEGIN{FS="_1.fq.gz"}{print $1}'`
do
    echo "Working on trimming genome $g with fastp"
    fastp -w 32 -i "$g"_1.fq.gz -I "$g"_2.fq.gz -o ./trimmed/"$g"_1.fq.gz -O ./trimmed/"$g"_2.fq.gz -h ./trimmed/"$g"_fastp.html -j ./trimmed/"$g"_fastp.json --detect_adapter_for_pe
done
echo
echo "Finished trimming"
```
so no --dedup option, because we tested it in **/home/genomics/mhannaert/assemblers_tryout** and it didn't had a lot of positive influence. 
So I edited this to fit it in the script:
```
#now perfroming fastp on the samples
#going back up to the samples
cd ..
#making a folder for the trimmed samples
mkdir -p "$OUT"/trimmed
#loop over read files
for g in `ls *_1.fq.gz | awk 'BEGIN{FS="_1.fq.gz"}{print $1}'`
do
    echo "Working on trimming genome $g with fastp" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
    fastp -w 32 -i "$g"_1.fq.gz -I "$g"_2.fq.gz -o "$OUT"/trimmed/"$g"_1.fq.gz -O "$OUT"/trimmed/"$g"_2.fq.gz -h "$OUT"/trimmed/"$g"_fastp.html -j "$OUT"/trimmed/"$g"_fastp.json --detect_adapter_for_pe 2>> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
done
echo
echo "Finished trimming" | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
```
after performen this was the output: 
````
Working on trimming genome 070_001_240321_001_0355_099_01_4691 with fastp
Detecting adapter sequence for read1...
No adapter detected for read1

Detecting adapter sequence for read2...
No adapter detected for read2

WARNING: fastp uses up to 16 threads although you specified 32
Read1 before filtering:
total reads: 7631849
total bases: 1141125367
Q20 bases: 1125478692(98.6288%)
Q30 bases: 1093512194(95.8275%)

Read2 before filtering:
total reads: 7631849
total bases: 1141072476
Q20 bases: 1114173176(97.6426%)
Q30 bases: 1065807647(93.404%)

Read1 after filtering:
total reads: 7534469
total bases: 1126426410
Q20 bases: 1113355586(98.8396%)
Q30 bases: 1084197858(96.2511%)

Read2 after filtering:
total reads: 7534469
total bases: 1126107965
Q20 bases: 1105561370(98.1754%)
Q30 bases: 1062147296(94.3202%)

Filtering result:
reads passed filter: 15068938
reads failed due to low quality: 186706
reads failed due to too many N: 8054
reads failed due to too short: 0
reads with adapter trimmed: 23930
bases trimmed due to adapters: 801462

Duplication rate: 17.2449%

Insert size peak (evaluated by paired-end reads): 262

JSON report: output_test2/trimmed/070_001_240321_001_0355_099_01_4691_fastp.json
HTML report: output_test2/trimmed/070_001_240321_001_0355_099_01_4691_fastp.html

fastp -w 32 -i 070_001_240321_001_0355_099_01_4691_1.fq.gz -I 070_001_240321_001_0355_099_01_4691_2.fq.gz -o output_test2/trimmed/070_001_240321_001_0355_099_01_4691_1.fq.gz -O output_test2/trimmed/070_001_240321_001_0355_099_01_4691_2.fq.gz -h output_test2/trimmed/070_001_240321_001_0355_099_01_4691_fastp.html -j output_test2/trimmed/070_001_240321_001_0355_099_01_4691_fastp.json --detect_adapter_for_pe 
fastp v0.23.4, time used: 52 seconds
Working on trimming genome 070_001_240321_001_0356_099_01_4691 with fastp
Detecting adapter sequence for read1...
No adapter detected for read1

Detecting adapter sequence for read2...
No adapter detected for read2

WARNING: fastp uses up to 16 threads although you specified 32
Read1 before filtering:
total reads: 4312678
total bases: 640655468
Q20 bases: 630987777(98.491%)
Q30 bases: 612716511(95.639%)

Read2 before filtering:
total reads: 4312678
total bases: 640659355
Q20 bases: 628645003(98.1247%)
Q30 bases: 607100148(94.7618%)

Read1 after filtering:
total reads: 4260888
total bases: 632919170
Q20 bases: 625017052(98.7515%)
Q30 bases: 608400597(96.1261%)

Read2 after filtering:
total reads: 4260888
total bases: 632643511
Q20 bases: 623693126(98.5852%)
Q30 bases: 604543820(95.5584%)

Filtering result:
reads passed filter: 8521776
reads failed due to low quality: 98222
reads failed due to too many N: 5358
reads failed due to too short: 0
reads with adapter trimmed: 19770
bases trimmed due to adapters: 550209

Duplication rate: 10.8003%

Insert size peak (evaluated by paired-end reads): 264

JSON report: output_test2/trimmed/070_001_240321_001_0356_099_01_4691_fastp.json
HTML report: output_test2/trimmed/070_001_240321_001_0356_099_01_4691_fastp.html

fastp -w 32 -i 070_001_240321_001_0356_099_01_4691_1.fq.gz -I 070_001_240321_001_0356_099_01_4691_2.fq.gz -o output_test2/trimmed/070_001_240321_001_0356_099_01_4691_1.fq.gz -O output_test2/trimmed/070_001_240321_001_0356_099_01_4691_2.fq.gz -h output_test2/trimmed/070_001_240321_001_0356_099_01_4691_fastp.html -j output_test2/trimmed/070_001_240321_001_0356_099_01_4691_fastp.json --detect_adapter_for_pe 
fastp v0.23.4, time used: 38 seconds
Finished trimming
````
This looks like it worked, I will also add fastp to the version list. 
I think this is too much info for the log file, so I think it's beter to create a log file specific for the fastp. 

this is a succes. 

## Shovill 
I will now add the part for shovill, for the assembly of the reads. I will use it with spades, because in **/home/genomics/mhannaert/assemblers_tryout** it showed that spades was the best option for our data. 
### making test data smaller
I will make a smaller test data set, so I can test the assembly. because otherwise it will take a long time to test with complete files. 
I will do this by using the program seqtk. https://github.com/lh3/seqtk

The command I used to perform this is the following: 
````
for sample in `ls *.fq | awk 'BEGIN{FS=".fq"}{print $1}'`; do seqtk sample -s100 $sample.fq 10000 > "$sample"_sub.fq ; done

 pigz *

mv *_sub.fq.gz ../subsample_gz/
````

the sample -s100 option and the 1000 is for the following: Subsample 10000 read pairs from two large paired FASTQ files (remember to use the same random seed to keep pairing)

after this was performed I reziped it to gz, because I want to test with gz format 

And then I moved them to a other folder so that I have tree folders of test data, one with bz2 files, one with normale gz files, and one with subsampled file of gz. I don't need a sub sample format for bz2 because I tested the part bz2/gz before and it worked so I will keep working with the gz files. 
### advise of supervisor 
I need to add removals of data that isn't need anymore. 
example: after reformating bz2 data to gz data I could remove the bz2 data. 
This is advised so that I will not use unnecessary data storage. 
for fastqc I already did this by removing the fastqc folder after performing multiqc. 

but now I will also add it to the step of remormating bz2 
I did this by adding the following line to the code: /

I don't need to add this in the code because when you decompress and compress and you remove -k option it will remove you original files and replace them. 

and later on when the assembly is done with shovill, I will remove the trimmed reads and only keep the informative files like the JSON and the HTML. 

### further with shovill 
The code I used to perform this was already a script: **/home/genomics/mhannaert/scripts/shovill_multi.sh**
So I will try to fit the information of the script in the my script. 

VSC crassed so I worked on my code in nano, but that's not very practise to document each part. 
I had some issues with were my log files and directories I made in this part were located, so I had to fix them. 
With all the fixes the code looks now likes this and works: 
````
#Shovill part
conda activate shovill
#making a folder for the output
mkdir -p "$OUT"/shovill
#making a log file for the shovill
touch "$OUT"/shovill/"$DATE_TIME"_shovill.log
#moving in to the file with the needed samples
cd "$OUT"/fastp/

FILES=(*_1.fq.gz)
#loop over all files in $FILES and do the assembly for each of the files
for f in "${FILES[@]}"
do
        SAMPLE=`basename $f _1.fq.gz`   #extract the basename from the file and store it in the variable SAMPLE

        #run Shovill
        shovill --R1 "$SAMPLE"_1.fq.gz --R2 "$SAMPLE"_2.fq.gz --cpus 16 --ram 16 --minlen 500 --trim -outdir ../shovill/"$SAMPLE"/ 2>> ../shovill/"$DATE_TIME"_shovill.log
        echo "==========================================================================" >> ../shovill/"$DATE_TIME"_shovill.log
        echo Assembly "$SAMPLE" done ! | tee -a ../"$DATE_TIME"_Illuminapipeline.log
done
#moving back to the main directory
cd ..
conda deactivate
````
To perform this I needed to rename my files form 070_001_240321_001_0355_099_01_4691_2_sub.fq.gz sub_070_0
01_240321_001_0355_099_01_4691_2.fq.gz form, otherwise they won't be recognised. 

## Extra part for Shovill
When I performed shovill I did after that an other step of selecting the needed files and putting them in a seperat folder
The inspiration I use for this part comes from the howto file: **\genomics\mhannaert\howto\rename_shovill_assemblies_howto.txt**
I can do the following command in my script: 
````
for d in `ls -d *`; do cp "$d"/contigs.fa assemblies/"$d".fna; done
````
the -d option:-d, --directory  list directories themselves, not their contents
In my script I fitted it like this: 
````
#selecting and moving needed files 
#moving to location top perform the following command
mkdir -p assemblies
cd shovill/
#collecting all the contigs.fa files in assemblies folder
echo "collecting contig files in assemblies/" | tee -a ../"$DATE_TIME"_Illuminapipeline.log
for d in `ls -d *`; do cp "$d"/contigs.fa ../assemblies/"$d".fna; done
````
Now I will test agin, output logfile: 
````
The user of 2024-05-08_13-26 is: mhannaert
====================================================================
the version that are used are:
FastQC v0.11.9
# packages in environment at /opt/miniforge3/envs/multiqc:
multiqc                   1.21               pyhdfd78af_0    bioconda
====================================================================
the command that was used is:
complete_illuminapipeline.sh /home/genomics/mhannaert/data/mini_testdata/subsample_gz/ output_test2 gz 4
This was performed in the following directory: /home/genomics/mhannaert
====================================================================
checking fileformat and reformat if needed
files are gz, so that's fine
Performing fastqc
performing multiqc

  /// MultiQC 🔍 | v1.21

|           multiqc | Search path : /home/genomics/mhannaert/data/mini_testdata/subsample_gz/output_test2/fastqc
|         searching | ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100% 76/76  
|            fastqc | Found 4 reports
|           multiqc | Report      : multiqc_report.html
|           multiqc | Data        : multiqc_data
|           multiqc | MultiQC complete
removing fastqc/
Working on trimming genome sub_070_001_240321_001_0355_099_01_4691 with fastp
Working on trimming genome sub_070_001_240321_001_0356_099_01_4691 with fastp
Finished trimming
Assembly sub_070_001_240321_001_0355_099_01_4691 done !
Assembly sub_070_001_240321_001_0356_099_01_4691 done !
collecting contig files in assemblies/
````
so that worked and I think the content of the logfile looks good 
I need to also add shovill to the version list, so I add in that part the following line:
````
conda activate shovill
conda list | grep shovill | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda deactivate
````
fastp wasn't added either so I changed that line to: 
````
fastp -v >> "$OUT"/"$DATE_TIME"_Illuminapipeline.log
````
I also want a clean env so as my supervisor advised, so I added the following lines of code: 
````
#removing the data that is not needed anymore 
echo "cleaning fastp and shovill" | tee -a "$DATE_TIME"_Illuminapipeline.log
rm fastp/*.fq.gz 
rm shovill/*/*{.fa,.gfa,.corrections,.fasta}
````
I also removed the parts about the shovill log file because shovill does this already
I tested my code again and it worked perfectly
I tested my code on the following data: 
**/home/genomics/mhannaert/data/mini_testdata/subsample_gz**

## Quast 
first I took a look again at the howto file and the existing script: **/home/genomics/mhannaert/howto/quast_howto.txt** **/home/genomics/mhannaert/scripts/quast_summary.sh**

there are two steps I need to do:
- perform quast 
- making a summary 

the code I added to the script was the following: 
````
#quast part 
conda activate quast
#making directory for quast output + making a log file 
mkdir -p quast 
touch quast/"$DATE_TIME"_quast.log
echo "performing quast" | tee -a "$DATE_TIME"_Illuminapipeline.log
for f in assemblies/*.fna; do quast.py $f -o quast/$f;done | tee -a quast/"$DATE_TIME"_quast.log

# Create a file to store the QUAST summary table
echo "making a summary of quast data" | tee -a "$DATE_TIME"_Illuminapipeline.log
touch quast/quast_summary_table.txt

# Add the header to the summary table
echo -e "Assembly\tcontigs (>= 0 bp)\tcontigs (>= 1000 bp)\tcontigs (>= 5000 bp)\tcontigs (>= 10000 bp)\tcontigs (>= 25000 bp)\tcontigs (>= 50000 bp)\tTotal length (>= 0 bp)\tTotal length (>= 1000 bp)\tTotal length (>= 5000 bp)\tTotal length (>= 10000 bp)\tTotal length (>= 25000 bp)\tTotal length (>= 50000 bp)\tcontigs\tLargest contig\tTotal length\tGC (%)\tN50\tN90\tauN\tL50\tL90\tN's per 100 kbp" >> quast/quast_summary_table.txt

# Initialize a counter
counter=1

# Loop over all the transposed_report.tsv files and read them
for file in $(find -type f -name "transposed_report.tsv"); do
    # Show progress
    echo "Processing file: $counter"

    # Add the content of each file to the summary table (excluding the header)
    tail -n +2 $file >> quast/quast_summary_table.txt

    # Increment the counter
    counter=$((counter+1))
done

conda deactivate
````
testing this part of the code. 

quast also makes an own log file, so that I made one isn't needed, so I remove that part from the script 
I test it now on an other data **/home/genomics/mhannaert/data/mini_testdata/gz_files**, because I got an error that there weren't any contigs of >=500, but I think that is because I work with this sub sampled reads, so I'm going to test that know on an other folder. 

When performd on bigger samples, quast indeed works. 

I also need to add quast to the version list. 
so I added the following line: 
````
conda activate quast
conda list | grep quast | tee -a "$OUT"/"$DATE_TIME"_Illuminapipeline.log
conda deactivate
````
## Busco
The following part of the script is Busco, I inspired my code on **/home/genomics/mhannaert/howto/busco_genomics2_howto.txt**

the code I added is: 
````
conda activate busco

echo "performing busco" | tee -a "$DATE_TIME"_Illuminapipeline.log
for sample in `ls assemblies/*.fna | awk 'BEGIN{FS=".fna"}{print $1}'`; do busco -i "$sample".fna -o busco/"$sample" -m genome --auto-lineage-prok -c 32 ; done

conda deactivate
````
I got some errors as output, that the file doesn't contain nulceotide sequences, so that's weird, When perfomed on all the data it worked, so that part works also 

Als I saw that the map asseblies is created every where, so I think I will remove that part and see the result from that. 

### extra part for busco 
There was in the howto file a part for making a plot as summary for the busco results so I'm also going to add that to the code, because it's easy to take a look at all the results in 1 figure
the code I added is: 
````
#extra busco part
#PLOT SUMMARY of busco
mkdir busco_summaries
echo "making summary busco" | tee -a "$DATE_TIME"_Illuminapipeline.log

cp busco/*/short_summary.specific.burkholderiales_odb10.*.txt busco_summaries/
cd busco_summaries/ 
 #to generate a summary plot in PNG
generate_plot.py -wd .
#going back to main directory
cd ..
````
The python script generate_plot.Py, I couldn't find it on the server. So I out commented this code, and will ask later at my supervisor. 
I tested the commands for the first part of this part by selecting and copying the files the the wright directory and that worked, so I thinks this part will work. 



