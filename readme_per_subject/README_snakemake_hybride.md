# Snakemake Hybride 
I will make a snakemake pipeline from my bash script **/home/genomics/mhannaert/scripts/complete_hybridepipeline.sh** and I will use my illumina snakemake as example. 

## setting up the snakemake enviroment
The structure I need in the enviroment: 
````
snakemake/
├─ Hybridepipeline/
|  ├─ .snakemake
│  ├─ data/
|  |  ├─sampels/
|  ├─ envs
|  ├─ snakefile
|  ├─ LICENSE
|  ├─ Scripts/
│  ├─ README
````
I made this: **/home/genomics/mhannaert/snakemake**

## snakefile 
The first step is making the CSV. 
So reading in the data. 
````
import os

# Define directories
REFDIR = os.getcwd()
#print(REFDIR)
sample_dir = REFDIR+"/data/samples"

sample_names = []
sample_list = os.listdir(sample_dir)
for i in range(len(sample_list)):
    sample = sample_list[i]
    if sample.endswith(".fq.gz"):
        samples = sample.split(".fq")[0]
        sample_names.append(samples)
        print(sample_names)
````
I just needed to remove the condition, because longreads don't have multiple conditions, it's just one file. 
I runned this already and it gave the following output: 
````
['GBBC_504_sup']
['GBBC_504_sup', 'GBBC502']
Assuming unrestricted shared filesystem usage.
Error: cores have to be specified for local execution (use --cores N with N being a number >= 1 or 'all')
````
So that's a good sign. 

So now I will add the rule all and the first rule for the csv part. 
First I will need to make a rule to ask for input because I need the chromosome size. 

-> S I discussed this with my supervisor and we think it's maybe beter to let the user make the csv file, because asking input in a snakemake isn't really common. 

-> maybe it's an idea to make a small shell script that can also be in the scripts directory, that people can run seperate from the snakemake, to easly make the csv file. I will ask my supervisor if this is a good idea. -> 

So the pipeline will start from an existing csv file and the first rule will be hybracter. 

So for my snakemake, 
in the output of hybracter you can have incomplete or complete, so I would like to check this, because I need to know this before doing other steps. 
