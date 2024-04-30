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

ALso testing if the script works for ".gz" files  -> 
still got this error in the beginning: 
````
Kraken_script/Kraken2.sh: line 30: gz: command not found
Kraken_script/Kraken2.sh: line 34: gz: command not found
````
but further the script works perfectly for ".gz" and ".bz2" files, even if they are in the same folder. 
