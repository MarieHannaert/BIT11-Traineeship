# Assemblers tryout 
we wanted to check witch assembler from the shovill pipeline the best option is for our data. 

All the script that are used can be found in the following directory:
/home/genomics/mhannaert/scripts

## The data 
the data is from the genomics server of ILVO. I downloaded this data from the ILVO server and then I used it for further analysis. 

I changed the data from a .bz2 file to a .gz file, because this was more compatible with the further steps. 

## Fastqc 
first checking the quality of the data. then I preformend a multiqc to save everything togheter. Then I deleted all the seperate fastqc files. 

Result can be found in output_fastqc (multiqc files). 
## Fastp 
I preformed the fastp, which will fast all-in-one preprocessing for FastQ files, cutting the adapters, in two ways. 

I performed this on the .gz files. 
The first way is without the --dedup option via the script fastp.sh 
this output can be found in the /assemblers_tryout/trimmed directory. 

The second time I added the --dedup option in the command in the script. This will remove the duplicates that are present. 
This output can be found in the /assemblers_tryout/trimmed_dup directory. 

## Assemblers
The assemblies was preformd via shovill pipeline. 
There are three assemblers that were used: skesa, spades, megahit. 

all three were performed on the files from the fastp. 
and all three were performed for the deduped and not deduped. 

All the output can be found in the following directories: 
/assemblers_tryoutoutput_megahit
/assemblers_tryout/output_spades
/assemblers_tryout/output_skesa
/assemblers_tryout/output_megahit_dup
/assemblers_tryout/output_spades_dup
/assemblers_tryout/output_skesa_dup

## Quast 
The result of the assemblers were processed with quast. This is a Quality Assessment Tool for Genome Assemblies. 
First we selected and renamed the needed files from the assemblers output with the following command: 

```
for d in `ls -d *`; do cp "$d"/contigs.fa assemblies/"$d".fna; done
 ```
The output can be found in the following directories: 
/assemblers_tryout/assemblie
/assemblers_tryout/assemblie_dup

Then we used the following command to run quast: 
```
conda activate quast
for f in *.fna; do quast.py $f -o output/$f;done
conda deactivate
```
Afther perfomring the quast we used the following script to get a summary file of all the quast files: 
quast_summary.sh 

## Excel 
In excel I added a column with type of assembler. Than I made one table of the deduped and not deduped and added also a column with this info. 

Output in the /assemblers_tryout. 

## Rstudio 
I used Rstudio to make some visualizations. 
This is done with the following script: vis_assemblers.R 
Here I made boxplots and beeswarms. 

first I compared the assemblers for the not dedup option. 
I visualized contigs and N50 per assembler. 
The assembler with the best result was spades for the no dedup option. 

second I did the same for the dedup option. 
The assembler with the best result was also spades. 

Because spades was the best option we visualized for spades the contigs and the N50 for dedup option and not dedup option. To compare the two options. 
The result was that there was no big difference between the option, also in running time this doesn't make a difference. 
