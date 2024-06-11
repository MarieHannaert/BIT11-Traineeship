# Nanopore_only pipeline
Marie Hannaert\
ILVO

The Nanopore pipeline is designed to analyze long-reads from Nanopore sequencing. This repository contains a Snakemake workflow tailored for analyzing bacterial genome long-read data. I developed this pipeline during my traineeship at ILVO-Plant.

## Installing the Nanopore pipeline
Snakemake is a workflow management system that helps create and execute data processing pipelines. It requires Python 3 and can be easily installed via the Bioconda package.

### Installing Mamba
First, isntall Miniforge:
#### Unix-like platforms (Mac OS & Linux)
````
$ curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
$ bash Miniforge3-$(uname)-$(uname -m).sh
````
or 
````
$ wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
$ bash Miniforge3-$(uname)-$(uname -m).sh
````
If this works, Mamba is installed. If not, check the Miniforge documentation here:
[MiniForge](https://github.com/conda-forge/miniforge#mambaforge)
### Installing Bioconda 
Perform a one-time setup of Bioconda with the following commands. This will modify your ~/.condarc file:
````
$ mamba config --add channels defaults
$ mamba config --add channels bioconda
$ mamba config --add channels conda-forge
$ mamba config --set channel_priority strict
````
If these steps are followed correctly, Bioconda should be installed. If not, refer to the documentation:  [Bioconda](https://bioconda.github.io/)
### Installing Snakemake 
Create the Snakemake environment by creating a Snakemake Mamba environment:
````
$ mamba create -c conda-forge -c bioconda -n snakemake snakemake
````
If successful, use the following commands to activate and check for help:
````
$ mamba activate snakemake
$ snakemake --help
````
For more documentation on Snakemake, visit: [Snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html)

### Downloading the Nanopore pipeline from Github
To use the Nanopore pipeline, download the complete pipeline, including scripts and Conda environments, to your local machine. It's good practice to create a **Snakemake/** directory to collect all your pipelines. Download the Nanopore pipeline into your Snakemake directory using: 
````
$ cd Snakemake/ 
$ git clone https://github.com/MarieHannaert/Nanopore_only_Snakemake.git
````
### Making the database that is used for skANI
For using skANI, you need to create a database. Follow the instructions here: 
[Creating a database for skANI](https://github.com/bluenote-1577/skani/wiki/Tutorial:-setting-up-the-GTDB-genome-database-to-search-against)

Once your database is installed, update the path to the database in the Snakefile at **Snakemake/Nanopore_only_Snakemake/Snakefile**, line 155. 

### Preparing checkM
Before running the pipeline, activate checkm_data:. 
````
$ conda activate .snakemake/conda/fc1c0b2ff8156a2c81f4d97546659744_ #This path can differ from yours
$ mkdir checkm_data
$ cd checkm_data
$ wget https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
$ tar -xvzf checkm_data_2015_01_16.tar.gz 
$ rm checkm_data_2015_01_16.tar.gz 
$ cd ..
$ export CHECKM_DATA_PATH=<your own path>
$ checkm data setRoot <your own path>
````
Verify the setup by running:
````
$ checkm test ~/checkm_test_results
````
### Preparing checkM2
Download the diamond database: 
````
$ conda activate .snakemake/conda/5e00f98a73e68467497de6f423dfb41e_ #This path can differ from mine
$ checkm2 database --download
$ checkm2 testrun
````

Now the snakemake enviroment is ready for use with the pipeline. 

## Executing the Nanopore pipeline 
Before executing the pipeline, perform the following preparatory steps:
### Preparing
In the **Nanopore_only_Snakemake/** directory, create the following directory: **data/samples**
````
$ cd Nanopore_only_Snakemake/
$ mkdir data/samples
````
Place the samples you want to analyze in the samples directory. They should be named like:
- sample1.fq.gz
- sample2.fq.gz

#### Making scripts executable 
Run the following command in the **Snakemake/Nanopore_only_Snakemake/** directory to make the scripts executable:
````
$ chmod +x scripts/*
````
This is necessary to execute the scripts used in the pipeline.

#### Personalize genomesize
The genome size is hardcoded in multiple lines. You need to change this to your genome size. Update the following lines in the Snakefile:
- 53
- 109

## Executing the Nanopore pipeline
Now, everything is ready to run the pipeline. To check the pipeline without generating output, use the following command in the **Nanopore_only_Snakemake/** directory: 
````
$ snakemake -np
````
This will give you an overview of all the steps in the pipeline.

To execute the pipeline with your samples in the **data/samples** directory, use: 
````
$ snakemake -j 4 --use-conda
````
The -j option specifies the number of threads to use, which you can adjust based on your local server. The --use-conda is needed for using the conda enviroments in the pipeline. 

### Pipeline content
The pipeline has eight major steps, along with some side steps for summaries and visualizations.
#### Nanoplot
NanoPlot is a tool for long-reads that provides an overview of the data quality, producing various visual outputs.

Nanoplot documentation: [Nanoplot](https://github.com/wdecoster/NanoPlot)
#### Filtlong
Filtlong filters long-reads based on their quality, using both read length and read identity.

Filtlong documentation: [Filtlong](https://github.com/rrwick/Filtlong)
#### Porechop ABI
Porechop ABI processes adapter sequences in ONT reads, discovering adapters directly from the reads and trimming them.

Porechop ABI documentation: [PorechopABI](https://github.com/bonsai-team/Porechop_ABI)
#### Flye
Flye is a tool for polishing long-reads, using output from Porechop ABI as input.

Flye documentation: [Flye](https://github.com/fenderglass/Flye)
#### Racon 
Racon generates genomic consensus of high quality, requiring Minimap2 to be run on Flye's output before combining it with Porechop ABI's output.

Racon documentation: [RACON](https://github.com/isovic/racon)
#### skANI
skANI calculates average nucleotide identity (ANI) from DNA sequences, outputting a summary file used for further analysis.

SkANI documentation: [skANI](https://github.com/bluenote-1577/skani)
#### Quast
Quast assesses genome assemblies, producing a summary file and various visualizations for quality assessment.

Quast documentation: [Quast](https://quast.sourceforge.net/)
#### Busco
BUSCO evaluates genome assembly and annotation completeness, providing a summary graph for up to fifteen samples.

Busco documentation: [Busco](https://busco.ezlab.org/)
#### CheckM
CheckM is a tool that assesses the quality of your assemblies, specifically for contamination. It comprises a set of tools that perform various checks on your assemblies.

CheckM documentation: [CheckM](https://github.com/Ecogenomics/CheckM/wiki)
#### CheckM2
CheckM2 is similar to CheckM but uses universally trained machine learning models. 

>This allows it to incorporate many lineages in its training set that have few - or even just one - high-quality genomic representatives, by putting it in the context of all other organisms in the training set.

From these result there will be made a summary table and then this summary table will be used also as input for the xlsx file: **skANI_Quast_checkM2_output.xlsx**.

CheckM2 documentation: [CheckM2](https://github.com/chklovski/CheckM2)
## Finish
After executing the pipeline, your **Nanopore_only_Snakemake/** directory will have the following structure:
````
Snakemake/
├─ Nanopore_only_Snakemake/
|  ├─ .snakemake
│  ├─ data/
|  |  ├─sampels/
|  ├─ envs
|  ├─ checkm_data/
|  ├─ scripts/
|  |  ├─beeswarm_vis_assemblies.R
|  |  ├─busco_summary.sh
|  |  ├─skani_quast_to_xlsx.py
|  ├─ Snakefile
│  ├─ results/
|  |  ├─01_nanoplot/
|  |  ├─02_filtlong/
|  |  ├─03_porechopABI/
|  |  ├─04_flye/
|  |  ├─05_racon/
|  |  ├─06_skani/
|  |  ├─07_quast/
|  |  ├─08_busco/
|  |  ├─09_checkm/
|  |  ├─10_checkm2/
|  |  ├─assemblies/
|  |  ├─busco_summary/
│  ├─ README
│  ├─ logs
````
## Overview of Nanopore pipeline
![A DAG of the Nanopore pipeline in snakemake](DAG_longread.png "DAG of the Nanopore pipeline")
