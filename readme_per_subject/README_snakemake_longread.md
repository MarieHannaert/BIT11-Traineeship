# Snakemake Longreads
I will make a snakemake pipeline from my bash script **/home/genomics/mhannaert/scripts/complete_longread.sh** and I will use my illumina snakemake as example. 

## setting up the snakemake enviroment
The structure I need in the enviroment: 
````
snakemake/
├─ Longreadpipeline/
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
The first step is reading in the data. 
````

````
