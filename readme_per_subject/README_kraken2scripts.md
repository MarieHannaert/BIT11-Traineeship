# Kraken2 script

The kraken2 tool needs to be performed on the illuina data. 
To do this efficiently it would be good to make a script from this that is reuseable for multiple samples.

https://github.com/DerrickWood/kraken2

https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1891-0
https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9725748/


## data 
The data were I will start from and base my script on is the illumina data that can be found in the data/00_reads directory. We need to start from the not trimmed data. 

## kraken2 tool
The tool is already installed on the genomics server so I will work there. I took a look at the man page of Kraken2, 
important parameters:

--gzip-compressed: Input files are compressed with gzip

--bzip2-compressed: Input files are compressed with bzip2

--threads : the number of threads to use 

-o for output folder 

To check the tool I performed the tool with only one sample so that I could check what the output is en must be if I run my script: 

````
 kraken2 --bzip2-compressed data/mini_testdata/070_001_240321_001_0355_099_01_4691_1.fq.bz2 --db /home/genomics/bioinf_databases/kraken2/NCBI_nt_20230205/ --report 070_001_240321_001_0355_099_01_4691_1_kraken2 --threads 24 --quick --memory-mapping
 ````

## the script 
I will check for the input directory of where the files are 
I will check if there is a option needed to specify that the files are zipped in a way, and check that way. 
To option for output file is also import to add 
and because of working on the server it is also important to specify the number of threads to use. 

To start the script I used the howto file of Kraken2 that already existed. 

The script I wrote can be found in: 
**/home/genomics/mhannaert/Kraken_script/Kraken2.sh**

## first try
I runned the script on four samples to see if the script worked 
samples: **/home/genomics/mhannaert/data/mini_testdata**

````
bash Kraken_script/Kraken2.sh data/mini_testdata/ output_kraken bz2 24
````

after I started the script I got this command: 
````
Kraken_script/Kraken2.sh: line 31: bz2: command not found
````
I went looking to the script on line 31, the error will probibly be in this part: 
```
#specifying type of compression 
if $COMP == "gz"
then 
    zip = "--gzip-compressed"

    if $COMP == "bz2"
    then
        zip = "--bzip2-compressed"
    fi
    
fi
```
But the script is executed despite the error. 
So I will wait till I got the output so I can check if it did something to the output or where it went wrong. 

I was heavy load on the server so I stopped the proces because other people coudn't use the server anymore. 

So I will perform the script at night and executed it when I leave. 

because it was a lot of load and not possible to perfom this on the server, we will look to options to make it less heavy: 
- not the whole NCBI_nt database, but maybe a more specific database 
- minikraken 

an option that was perposed by steve is: 
https://genomebiology.biomedcentral.com/articles/10.1186/s13059-024-03244-4 



## Krona tool 
https://telatin.github.io/microbiome-bioinformatics/Kraken-to-Krona/

This tool is not installed on the server, 
I purposed to install it there to because than we can add this to the same script, otherwise it must be performed on multiple locations (server, wsl) 
-> my superviser thaught this was a good idea, so we asked IT

It is installed, so I will add this command to the script so that it all will be executed in one script: 
````
ktImportTaxonomy -t 5 -m 3 -o "$OUT"/"$sample"_krona.html "$OUT"/"$sample"_kraken2.report
````

## second try
I will run the script again on the same data on the server at night. 

the command
````
bash Kraken_script/Kraken2.sh data/mini_testdata/ output_kraken bz2 16
````
Only two samples so that it will perform faster and with 16 so it isn't to heavy on the server 

The Kraken is still running 
I stopped it because I think we will beter doe it with an other db, smaller and more specific one. 

also I forgot to activate the krona env so that part of the script won't have worked. 

## third try 
I replace the database with a new one: 
**/home/genomics/bioinf_databases/kraken2/Standard**

I runned it with the following comand: 
````
bash Kraken_script/Kraken2.sh data/mini_testdata/ output_kraken bz2 8
````
I runned it again on my four test samples, because I first want to know I my script works before I test it on all te samples. 

finished very fast, so changing from database is the solution. 
But the krona didn't run, because the file names didn't match. 

I changed in de report by adding ".report" to the output file name. 

## fourth try
I runned the script again on the same data, after changing the script. 

I got again a warning: 
````
Importing output_kraken/070_001_240321_001_0356_099_01_4691_2_kraken2.report...
   [ WARNING ]  The following taxonomy IDs were not found in the local database and were set to root (if they were recently added to NCBI, use updateTaxonomy.sh to update the local
                database): 1740163 3043410 2917990
Writing output_kraken/070_001_240321_001_0356_099_01_4691_2_krona.html...
Finished running Kraken2 and Krona
````
But I also got output, so I think it's fine. 

## running on full dataset 
I executed the following command: 
```
bash Kraken_script/Kraken2.sh data/00_reads output_kraken_complete bz2 8
```

the result can be found in: 
**/home/genomics/mhannaert/Kraken_script/output_kraken_complete**

I got the following: 
````
Kraken_script/Kraken2.sh: line 52: /GBBC_779_2_krona.html: No such file or directory
rm: cannot remove '*_kraken2.report': No such file or directory
Kraken_script/Kraken2.sh: line 57: syntax error near unexpected token `done'
Kraken_script/Kraken2.sh: line 57: `done'
````
I made a mistake in naming the krona file en in the part of rm I forgot to add the directory, so I checnged that. 


## smalle updates in the script 
adding the removal of the kraken reports after the krona has performed 
````
rm *.kraken2.report
````
testing this on test set -> The first updates worked and the errors are gone. 

ALso testing if the script works for ".gz" files **/home/genomics/mhannaert/data/mini_testdata** -> 
still got this error in the beginning: 
````
Kraken_script/Kraken2.sh: line 30: gz: command not found
Kraken_script/Kraken2.sh: line 34: gz: command not found
````
but further the script works perfectly for ".gz" and ".bz2" files, even if they are in the same folder. 

## execute the skani on the assemblies 
skani is a program for calculating average nucleotide identity (ANI) from DNA sequences (contigs/MAGs/genomes) for ANI > ~80%.

-> identification and clustering against an annotated database

https://github.com/bluenote-1577/skani

to perform this I used the following command: 
````
skani search *_spades.fna -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o skani_results_file.txt -t 24 -n 1
````
The result can be found in: 
**/home/genomics/mhannaert/assemblers_tryout/assemblie/skani_results_file.txt**

You can now see in this result that there are three different "species" that can be found:
-> for the sample 759 you can clearly see that it is an other: Rhodococcus erythropolis

-> In the other samples there is again two different variants of the same species: 
1. Ralstonia pseudosolanacearum
2. Ralstonia solanacearum

so this is a good thing to do if you see strange results after an anvio visualisation, because this could tell you whats is different and confirm the differences that you see in other results. 

## extra updates for the script 
### options that can be added

1. Log  
2. check of the input and output file exist 
3. logging important information like: user of the script, versions of programs and what was the exact command

### making these options 
#### adding a log file 
My supervisor already gave me this information to add a log file. 
````
#for a title for the log file
DATE_TIME=$(date+"%d-%m-%y_%H-%M")

#an example of a log file command
fastp -w 16 -i "$g"_1.fq.gz -I "$g"_2.fq.gz -o ./trimmed/"$g"_1.fq.gz -O ./trimmed/"$g"_2.q.z -h ./trimmed/"$g"_fastp.html --detect_adapter_for_pe |tee >> ./trimmed/fastp_"$DATE_TIME".log

#update of the previous command 
tee -a ./trimmed/fastp_"$DATE_TIME".log

#last update of the command
2>&1 |tee -a fastp_"$DATE_TIME".log
````
So now I'm going to try to make this in to my Kraken2.sh, just to learn making this and to see if it works. 

````
#making the paremeter of the data of that specific day 
DATE_TIME=$(date+"%d-%m-%y_%H-%M")

#making a log file that conatians the data in the title
touch "$OUT"/"$DATE_TIME"_kraken2.log

#adding after each command
2>&1 |tee -a "$OUT"/"$DATE_TIME"_kraken2.log
````
#### adding logging important information
I added the following information to the log file: 
````
echo "The user of today is" $USER | tee -a "$OUT"/"$DATE_TIME"_kraken2.log

# adding the versions of the tools that are used 
echo "the version that are used are:" | tee -a "$OUT"/"$DATE_TIME"_kraken2.log
Kraken2 -v | tee -a "$OUT"/"$DATE_TIME"_kraken2.log
mamba list | grep krona | tee -a "$OUT"/"$DATE_TIME"_kraken2.log 

#adding the command to the log file
echo "the command that was used is:"
history | tail -2|head -1 |tee -a "$OUT"/"$DATE_TIME"_kraken2.log 
````
#### testing current changes 
I will test the script again by running the script again on the **/home/genomics/mhannaert/data/mini_testdata** 
 I used the following command: 
 ````
 Kraken2.sh mini_testdata/ output_test bz2 4
 ````
 The date wasn't wright, so I cahnaged that part: 
 ````
DATE_TIME=$(date '+%Y-%m-%d_%H-%M')
 ````
 output in the log file is: (I stopped it early because I only first wanted to test my log file): 
 ````
  GNU nano 6.2                                                                  2024-05-02_12-05_kraken2.log                                                                           The user of today is mhannaert
the version that are used are:
# packages in environment at /opt/miniforge3/envs/krona:
krona                     2.8.1           pl5321hdfd78af_1    bioconda
Loading database information... done.
 ````
 So there is something wrong with the version adding of kraken 

The kraken2 command was typed with a capital so that was the problem 
rerun and worked, so now I will let I run completley to see if it also add the other command for each sample

the output looks like this: 
````
The user of today is mhannaert
====================================================================
the version that are used are:
Kraken version 2.1.2
Copyright 2013-2021, Derrick Wood (dwood@cs.jhu.edu)
# packages in environment at /opt/miniforge3/envs/krona:
krona                     2.8.1           pl5321hdfd78af_1    bioconda
====================================================================
====================================================================
Loading database information... done.
C       LH00201:19:22HT2CLT3:5:1101:1379:1048   48736   148     48736:Q
C       LH00201:19:22HT2CLT3:5:1101:15230:1048  305     140     305:Q
C       LH00201:19:22HT2CLT3:5:1101:18244:1048  48736   151     48736:Q
C       LH00201:19:22HT2CLT3:5:1101:18484:1048  305     151     305:Q
C       LH00201:19:22HT2CLT3:5:1101:26529:1048  28216   151     28216:Q
...
````
So the command isn't saved in the log file 
the rest looks good 

I changed that part about adding the command to the log file to: 
````
echo "Kraken2.sh $1 $2 $3 $4 |tee -a "$OUT"/"$DATE_TIME"_kraken2.log
````
Because, if you execute the script it is the script name and then the commands, so that part can be hard coded. 
I tested it and it gave this output: 
````
The user of today is mhannaert
====================================================================
the version that are used are:
Kraken version 2.1.2
Copyright 2013-2021, Derrick Wood (dwood@cs.jhu.edu)
# packages in environment at /opt/miniforge3/envs/krona:
krona                     2.8.1           pl5321hdfd78af_1    bioconda
====================================================================
The user of today is mhannaert
====================================================================
the version that are used are:
Kraken version 2.1.2
Copyright 2013-2021, Derrick Wood (dwood@cs.jhu.edu)
# packages in environment at /opt/miniforge3/envs/krona:
krona                     2.8.1           pl5321hdfd78af_1    bioconda
====================================================================
Kraken2.sh mini_testdata/ output_test bz2 4
====================================================================
Loading database information... done.
````
There is a sentence gone, I just forgot to add "| tee -a "$OUT"/"$DATE_TIME"_kraken2.log" part to the line. 

I also added the working directory to the log file. Because then you will know everything
````
#saving the pwd before changing it to the outputfolder
START_DIR=$(pwd)
#adding it to the log file
echo "This was performd in the following directory: $START_DIR" |tee -a "$OUT"/"$DATE_TIME"_kraken2.log
````
this worked 

#### found the solution to the error of bz2
The error that already was there from the beginning 
````
Kraken_script/Kraken2.sh: line 30: gz: command not found
Kraken_script/Kraken2.sh: line 34: gz: command not found
````
Was because I didn't have the double brackets around my conditions in my if status. 
so I changed it to: 
````
if [[ $3 == "gz" ]];
    then 
        zip="--gzip-compressed"
elif [[ $3 == "bz2" ]];
    then
        zip="--bzip2-compressed"
fi
````
This solved the error, also that there must be spaces between the brackets and the conditions. 
#### checking the existing of input file and output file 
The output doesn't need to be checked because it will be created when it doesn't exist. 

for the input directory, this needed to be check directly after checking if all the parameters are given by the script, so I added right after that the following:
````
#checking if the input directory exist 
echo "the given input directory is:" $1 
if [ -d "$DIR" ]; then
    echo "$DIR exist."
else 
    echo "$DIR does not exist. Give a correct path in the command"
	exit 1;
fi
````
If the input directory doesn't exist, the script will stop and give an error.

An other option is to ask again for a directory ad update the $DIR variable:
````
echo "the given input directory is:" $1 
if [ -d "$DIR" ]; then
    echo "$DIR exist."
else 
    echo "$DIR does not exist. Give a correct path:"
	read DIR;
fi
````

This worked whenI didn't gave a correct path it asked for a new path and used the variable 
````
the given input directory is: min_testdata/
min_testdata/ does not exist. Give a correct path:
mini_testdata/
The user of today is mhannaert
====================================================================
the version that are used are:
Kraken version 2.1.2
Copyright 2013-2021, Derrick Wood (dwood@cs.jhu.edu)
# packages in environment at /opt/miniforge3/envs/krona:
krona                     2.8.1           pl5321hdfd78af_1    bioconda
====================================================================
the command that was used is:
Kraken2.sh min_testdata/ output_try bz2 4
This was performed in the following directory: /home/genomics/mhannaert/data
====================================================================
````
The checing for the input directory is not correct, because it will ask one time for a new directory but when that new directory is also not correct it will not ask again

I changed it to the followig loop with help from blackbow AI: 
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
I tested it and it worked 
For the gile type I also added the following: 
````
else
    echo "The compression type is not supported, only use .gz or .bz2"
    exit 1
````

#### updating the log 
When I performed the the script wrote EVERYTHING to the log file so that file became to big. 
So I only add the steps and for the command I only add the error if this occures. 

so " 2>" ipv "2>&1" 

These gave an error 
````
../scripts/Kraken2.sh: line 73: syntax error near unexpected token `|'
../scripts/Kraken2.sh: line 73: `    kraken2 $zip "$sample".fq.$3 --db /home/genomics/bioinf_databases/kraken2/Standard --report "$OUT"/"$sample"_kraken2.report --threads $4 --quick --memory-mapping 2> |tee -a "$OUT"/"$DATE_TIME"_kraken2.log'
````
I changed the "2> | tee -a" to "2>>" the error will not be printed in the terminal and only added to the log file, but that's okay, because when something goes wrong, the program will stop and then you can just check the log file. 
This solved the error 

The output looks like this and that's a good output: 
````
The user of today is mhannaert
====================================================================
the version that are used are:
Kraken version 2.1.2
Copyright 2013-2021, Derrick Wood (dwood@cs.jhu.edu)
# packages in environment at /opt/miniforge3/envs/krona:
krona                     2.8.1           pl5321hdfd78af_1    bioconda
====================================================================
the command that was used is:
Kraken2.sh min_testdata/ output_try bz2 4
This was performed in the following directory: /home/genomics/mhannaert/data
====================================================================
Running Kraken2 on 070_001_240321_001_0355_099_01_4691_1
Loading database information... done.
7631849 sequences (1141.13 Mbp) processed in 356.923s (1282.9 Kseq/m, 191.83 Mbp/m).
  7616079 sequences classified (99.79%)
  15770 sequences unclassified (0.21%)
Running Krona on 070_001_240321_001_0355_099_01_4691_1
   [ WARNING ]  Score column already in use; not reading scores.
   [ WARNING ]  The following taxonomy IDs were not found in the local database and were set to root (if they were recently added to NCBI, use updateTaxonomy.sh to update the local
                database): 3043410 1740163
Removing kraken2 report
Running Kraken2 on 070_001_240321_001_0355_099_01_4691_1
Loading database information... done.

````
Thus the scripts work till here. 
I could do more options but I think it would be an overkill for what the script has to do, it was a great exercise. My supervisor also said that it was good and that is was good for me to make everything and try everything on such a small script to practise. 
The last log file of the last run can be found in my Onenote ELN on 03/05/2024. 
Part output of last log file:
````
The user of today is mhannaert
====================================================================
the version that are used are:
Kraken version 2.1.2
Copyright 2013-2021, Derrick Wood (dwood@cs.jhu.edu)
# packages in environment at /opt/miniforge3/envs/krona:
krona                     2.8.1           pl5321hdfd78af_1    bioconda
====================================================================
the command that was used is:
Kraken2.sh mini_testdata/ output_test gz 4
This was performed in the following directory: /home/genomics/mhannaert/data
====================================================================
Running Kraken2 on 070_001_240321_001_0355_099_01_4691_1
Loading database information... done.
7631849 sequences (1141.13 Mbp) processed in 4900.504s (93.4 Kseq/m, 13.97 Mbp/m).
  7616079 sequences classified (99.79%)
  15770 sequences unclassified (0.21%)
Running Krona on 070_001_240321_001_0355_099_01_4691_1
   [ WARNING ]  Score column already in use; not reading scores.
   [ WARNING ]  The following taxonomy IDs were not found in the local database and were set to root (if they were recently added to NCBI, use updateTaxonomy.sh to update the local
                database): 1740163 3043410
Removing kraken2 report
````
## last error found in the script 
When I performed the script In the log file I saw that the command was 8x performed, but it must only be 4x, I think the error will be in the selecting the .gz and .bz2. Because In the directory are 8 files, 4 .gz and 4.bz2 so I think it did both and not only the one you select. Because of log file, I saw the error. 

I changed the elif to if:
````
if [[ $3 == "gz" ]];
    then 
        zip="--gzip-compressed"
fi

if [[ $3 == "bz2" ]];
      then
        zip="--bzip2-compressed"
fi
````
but this didn't change the error and again eight samples were processed 
I changed the double brackets to single brackets: 
````
if [ $3 == "gz" ];
    then 
        zip="--gzip-compressed"
fi

if [ $3 == "bz2" ];
      then
        zip="--bzip2-compressed"
fi
````
This didn't work either, blackbox AI told my, my error was in the line "for samples in..." 
there the .fq.* must be .fq.$3 
````
for sample in `ls *.fq.$3 | awk 'BEGIN{FS=".fq.*"}{print $1}'`
````
-> this would solve the problem normaly 
I changed back the previouse changes and tested this
This indeed solved this error. 



