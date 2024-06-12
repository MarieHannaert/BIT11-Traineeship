# Illumina pipeline
Marie Hannaert\
ILVO

The Illumina pipeline is designed to analyze short-reads from Illumina sequencing. This repository contains a Snakemake workflow that can be used to analyze short-read data specific to bacterial genomes. Everything you need can be found in this repository. I developed this pipeline during my traineeship at ILVO-Plant.

## Installing the Illumina pipeline
Snakemake is a workflow management system that helps create and execute data processing pipelines. It requires Python 3 and can be most easily installed via the Bioconda package..

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


### Downloading the Illumina pipeline from Github
When you want to use the Illumina pipeline, you can download the complete pipeline, including scripts, conda environments, etc., on your local machine. A good practice is to create a directory called **Snakemake/** where you can collect all of your pipelines. Downloading the Illumina pipeline into your Snakemake directory can be done with the following commands:
````
$ cd Snakemake/ 
$ git clone https://github.com/MarieHannaert/Illumina_Snakemake.git
````
### Making a database for Kraken2
For Kraken2, you need to create a database. The database used in this pipeline is the [Standard database](https://benlangmead.github.io/aws-indexes/k2). 
After downloading, you need to specify the path to this database in the **Snakemake/Illumina_Snakemake/Snakefile**, line 73.

### Making the database that is used for skANI
To use skANI, you need a database. You can create one according to the following link:
[Creating a database for skANI](https://github.com/bluenote-1577/skani/wiki/Tutorial:-setting-up-the-GTDB-genome-database-to-search-against)

When your database is installed, change the path to the database in the Snakefile **Snakemake/Illumina_Snakemake/Snakefile**, line 152. 

### Preparing checkM2
You need to download the diamond database for CheckM2: 
````
$ conda activate .snakemake/conda/5e00f98a73e68467497de6f423dfb41e_ #This path can differ from mine
$ checkm2 database --download
$ checkm2 testrun
````

Now the snakemake enviroment is ready for use with the pipeline. 
## Executing the Illumina pipeline 
Before you can execute this pipeline, you need to perform a couple of preparatory steps.
### Preparing
In the **Illumina_Snakemake/** directory, you need to create the following directories: **data/samples**
````
$ cd Illumina_Snakemake/
$ mkdir data/samples
````
In the samples directory, place the samples that you want to analyze. They must look like the following two samples:
- sample1_1.fq.gz
- sample1_2.fq.gz
- sample2_1.fq.gz
- sample2_2.fq.gz

If this is done there is one more important step left: 
#### Activation of Krona 
To install the local taxonomy database, run the following commands: 
````
$ bash .snakemake/conda/cce02dcec3898e2025b146bc478991b8/opt/krona/updateTaxonomy.sh
````
!The number of the conda environment can differ from the one above; you need to check this when you do the installation.!

Before you can find this, you will probably need to execute Snakemake one time. This is needed because it will install the required conda environments. So if you get an error, don't panic; this is normal during the first execution. More info can be found on: [KronaTools](https://github.com/marbl/Krona/wiki/Installing)

#### Making scripts executable 
To make the scripts executable, run the following command in the **Snakemake/Illumina_Snakemake/** directory:
````
$ chmod +x scripts/*
````
This is needed because otherwise, the scripts used in the pipeline cannot be executed. 

## Executing the Illumina pipeline
Now everything is ready to run the pipeline.
If you want to run the pipeline without any output, just to check if it works, use the following command in the **Illumina_Snakemake/** directory: 
````
$ snakemake -np
````
Now you will get an overview of all the steps in the pipeline. 

If you want to execute the pipeline and your samples are place in the **data/samples** directory, you can use the following command: 
````
$ snakemake -j 4 --use-conda
````
The -j option specifies the number of threads to use, which you can adjust based on your local server. The --use-conda option is needed to use the conda environments in the pipeline.

### Pipeline content
The pipeline has eight main steps. Besides these steps, there are some side steps to create summaries and visualizations.
#### Fastqc 
This step is done on the samples and generates a quality report for each sample.

FastQC documentation: [Fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
#### Multiqc
MultiQC will generate one HTML report from all the FastQC reports. 

Multiqc documentation: [Multiqc](https://multiqc.info/docs/)
#### Kraken2
Kraken2 will start from the samples themselves and generate a report file for each sample. Kraken2 is a taxonomic classification system using exact k-mer matches to achieve high accuracy and fast classification speeds.

Kraken2 documentation: [Kraken2](https://ccb.jhu.edu/software/kraken2/)
#### Krona
Krona will use the report files generated by Kraken2. Krona will create a Krona plot from this information to visualize the reports.

Krona documentation: [Krona](https://github.com/marbl/Krona/wiki/KronaTools)
#### Fastp
Fastp will start from the samples and use the pairs. Fastp will trim the reads so that these reads are ready for assembly.

Fastp documentation: [Fastp
](https://github.com/OpenGene/fastp)
#### Shovill
Shovill will perform the assembly from the output of Fastp. The assembly will be done with SPAdes.

Shovill documentation: [Shovill](https://github.com/tseemann/shovill)
#### skANI
skANI is a program for calculating average nucleotide identity (ANI) from DNA sequences (contigs/MAGs/genomes) for ANI > ~80%. The output of skANI is a summary file: **skani_results_file.txt**. This info will be put into an XLSX file together with the Quast summary file.

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
When your done executing the pipeline, you will find the following structure in you **Illumina_Snakemake/**:
````
Snakemake/
├─ Illumina_Snakemake/
|  ├─ .snakemake
│  ├─ data/
|  |  ├─sampels/
|  ├─ envs
|  ├─ scripts/
|  |  ├─beeswarm_vis_assemblies.R
|  |  ├─summaries_busco.sh
|  |  ├─skani_quast_checkm2_to_xlsx.py
|  ├─ Snakefile
│  ├─ results/
|  |  ├─00_fastqc/
|  |  ├─01_multiqc/
|  |  ├─02_Kraken2/
|  |  ├─03_krona/
|  |  ├─04_fastp/
|  |  ├─05_shovill/
|  |  ├─06_skani/
|  |  ├─07_quast/
|  |  ├─08_busco/
|  |  ├─09_checkm2/
|  |  ├─assemblies/
|  |  ├─busco_summary/
│  ├─ README
│  ├─ logs
````
## Overview of Illumina pipeline
![A DAG of the illumina pipeline in snakemake](dag.png "DAG of the Illumina pipeline")