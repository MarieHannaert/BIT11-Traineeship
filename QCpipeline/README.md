# Assembly QC pipeline
Marie Hannaert\
ILVO

The Assembly QC pipeline is designed to perform quality control on assemblies of bacterial genomes. This repository contains a Snakemake workflow that can be used to analyze assemblies specific to bacterial genomes. Everything you need can be found in this repository. I developed this pipeline during my traineeship at ILVO-Plant. 

## Installing the assembly QC pipeline
Snakemake is a workflow management system that helps create and execute data processing pipelines. It requires Python 3 and can be most easily installed via the Bioconda package.

### Installing Mamba
The first step to installing Mamba is installing Miniforge:
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
If this worked, the installation of Mamba is done. If not, you can check the Miniforge documentation at the following link:
[MiniForge](https://github.com/conda-forge/miniforge#mambaforge)

### Installing Bioconda 
Then, perform a one-time setup of Bioconda with the following commands. This will modify your ~/.condarc file:
````
$ mamba config --add channels defaults
$ mamba config --add channels bioconda
$ mamba config --add channels conda-forge
$ mamba config --set channel_priority strict
````
If you followed these steps, Bioconda should be installed. If it still doesn't work, you can check the documentation at the following link: [Bioconda](https://bioconda.github.io/)
### Installing Snakemake 
Now, create the Snakemake environment. We will do this by creating a Snakemake Mamba environment:
````
$ mamba create -c conda-forge -c bioconda -n snakemake snakemake
````
If this was successful, you can now use the following commands for activation and for help: 
````
$ mamba activate snakemake
$ snakemake --help
````
To check the Snakemake documentation, you can use the following link: [Snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html)

### Downloading the assembly QC pipeline from Github
When you want to use the Assembly QC pipeline, you can download the complete pipeline, including scripts, conda environments, etc., on your local machine. A good practice is to create a directory called **Snakemake/** where you can collect all of your pipelines. Downloading the Assembly QC pipeline into your Snakemake directory can be done with the following command 
````
$ cd Snakemake/ 
$ git clone https://github.com/MarieHannaert/Long-read_Snakemake.git
````
### Making the database that is used for skANI
To use skANI, you need to create a database. You can do this by following the instructions at the following link:
[Creating a database for skANI](https://github.com/bluenote-1577/skani/wiki/Tutorial:-setting-up-the-GTDB-genome-database-to-search-against)

When your database is installed, change the path to the database in the Snakefile  **Snakemake/Assembly_QC_Snakemake/Snakefile**, line 155. 


### Preparing checkM2
You also need to download the diamond database for CheckM2:
````
$ conda activate .snakemake/conda/5e00f98a73e68467497de6f423dfb41e_ #This path can differ from mine
$ checkm2 database --download
$ checkm2 testrun
````

Now the snakemake enviroment is ready for use with the pipeline. 

## Executing the assembly QC pipeline 
Before you can execute this pipeline, you need to perform a couple of preparing steps. 
### Preparing
In the **Assembly_QC_Snakemake/** directory, you need to create the following directories: **data/assemblies**
````
$ cd Assembly_QC_Snakemake/
$ mkdir data/assemblies
````
In the assemblies directory, place the assemblies that you want to analyze. They must look like the following two assemblies:
- sample1.fna
- sample2.fna

#### Making scripts executable 
To make the scripts executable, run the following command in the **Snakemake/Assembly_QC_Snakemake/** directory:
````
$ chmod +x scripts/*
````
This is needed because otherwise, the scripts used in the pipeline cannot be executed.

#### Personalize genomesize
The genome size is hardcoded in multiple lines. You need to change this to your genome size. The lines in the Snakefile where you need to change this are:
- line 53
- line 109

## Executing the assembly QC pipeline
Now everything is ready to run the pipeline.
If you want to run the pipeline without any output, just to check if it works, use the following command in the **Assembly_QC_Snakemake/** directory: 
````
$ snakemake -np
````
You will get an overview of all the steps in the pipeline. 

If you want to execute the pipeline and your assemblies are placed in the **data/assemblies** directory, you can use the following command: 
````
$ snakemake -j 4 --use-conda
````
The -j option specifies the number of threads to use, which you can adjust based on your local server. The --use-conda option is needed to use the conda environments in the pipeline.

### Pipeline content
The pipeline has five main steps. Besides these steps, there are some side steps to create summaries and visualizations. 

#### skANI
skANI is a program for calculating average nucleotide identity (ANI) from DNA sequences (contigs/MAGs/genomes) for ANI > ~80%. The output of skANI is a summary file: **skani_results_file.txt**. This information will be put into an XLSX file together with the Quast summary file.

SkANI documentation: [skANI](https://github.com/bluenote-1577/skani)
#### Quast
Quast is a Quality Assessment Tool for Genome Assemblies by CAB. The output will be a directory for each sample. From these directories, we will create a summary file: **quast_summary_table.txt**. The information from this summary file will also be added to the XLSX file together with the skANI summary file. The result can be found in the file **skANI_Quast_checkM2_output.xlsx**. From the Quast summary file, we will also create some beeswarm visualizations for the number of contigs and the N50. This can be found in the file **beeswarm_vis_assemblies.png**.

Quast documentation: [Quast](https://quast.sourceforge.net/)
#### Busco
Assessing Genome Assembly and Annotation Completeness. Based on evolutionarily-informed expectations of gene content of near-universal single-copy orthologs, the BUSCO metric is complementary to technical metrics like N50. The output of BUSCO is a directory for each sample. To make it more visible, a summary graph will be created for every fifteen assemblies.

Busco documentation: [Busco](https://busco.ezlab.org/)

#### CheckM2
CheckM2 is similar to CheckM, but CheckM2 has universally trained machine learning models.

>This allows it to incorporate many lineages in its training set that have few - or even just one - high-quality genomic representatives, by putting it in the context of all other organisms in the training set.

From these results, a summary table will be created and used as input for the XLSX file:  **skANI_Quast_checkM2_output.xlsx**.

CheckM2 documentation: [CheckM2](https://github.com/chklovski/CheckM2)
## Finish
When you're done executing the pipeline, you will find the following structure in your  **assembly_QC_Snakemake/**:
````
Snakemake/
├─ Assembly_QC_Snakemake/
|  ├─ .snakemake
│  ├─ data/
|  |  ├─assemblies/
|  ├─ envs
|  ├─ scripts/
|  |  ├─beeswarm_vis_assemblies.R
|  |  ├─summaries_busco.sh
|  |  ├─skani_quast_checkm2_to_xlsx.py
|  ├─ Snakefile
│  ├─ results/
|  |  ├─skani/
|  |  ├─quast/
|  |  ├─busco/
|  |  ├─checkM2/
|  |  ├─busco_summary/
|  |  ├─skANI_Quast_checkM2_output.xlsx
│  ├─ README
│  ├─ logs
````
## Overview of assembly QC pipeline
![A DAG of the assembly QC pipeline in snakemake](DAG_QC.png "DAG of the assembly QC pipeline")
