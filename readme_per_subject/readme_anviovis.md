# Anvio visualizatie 

I will make a pangenomic anvio visualisation of the data I got from the spades assembly without dedup option. 

## reformating the fna files
I will do this by using the existing script that can be found in 
**/home/genomics/mhannaert/scripts/anvi-reformat-fasta.sh**
The output of this step can be found in the following directory: 
**/home/genomics/mhannaert/anvio_visualisatie/reformatted**

## running the anvio_gen_contigs_db.sh script 
This will perform multiple steps.
executed:
````
mamba activate anvio
bash ../../scripts/anvio_gen_contigs_db.sh 
````
because the script was still running at 17h. I stopped the proces, the samples that were not done yet I placed in a folder called: **/home/genomics/mhannaert/anvio_visualisatie/reformatted/tmux_sessie_tijdelijk**

and I started a tmux session were I did the same command as before but now in this folder, so it can continou when I go home. 

It is finished 

## looking at the results
following command 
````
anvi-display-contigs-stats *db
````
I got some graphs and a table as output, I could compare two samples with each other. 

I also runned the next commands: 
````
anvi-script-gen-genomes-file --input-dir . -o external-genomes.txt
anvi-estimate-genome-completeness -e external-genomes.txt
````
The output that I got was a table, this following sample looks different GBBC_759_spades and GBBC_759_B_spades: 
The output is saved in the following document: 
**/home/genomics/mhannaert/anvio_visualisatie/output_anvio_genome_completeness.txt**

## for the visualisatie 
I didn't understand the following command: 
````
anvi-display-pan -g Cf_final_GENOMES.db \
                 -p Cf_final_SPLIT/SCG/Cf_final-PAN.db
````
The first part are my samples, but I didn't know where the get the second part of the command. 
This part apperently already exist and can be found in a subfolder. 

I called with my supervisor, and i was wrong, I need first to perform two steps

creating Genome.db, I did this by the following command: 
````
anvi-gen-genomes-storage -e external-genomes.txt                         -o GENOMES.db
````
output: 
````
The new genomes storage ......................: GENOMES.db (v7, signature: hash9bb588f0)
Number of genomes ............................: 59 (internal: 0, external: 59)
Number of gene calls .........................: 279,034
Number of partial gene calls .................: 2,231
````
Then I have to make the Pan by the following command: 
````
anvi-pan-genome -g GENOMES.db \
               --project-name anvio_vis_pan \
               --num-threads 48
               --exclude-partial-gene-calls
````
output: 
````
Functions found ..............................: KEGG_BRITE, KOfam, COG20_FUNCTION, COG20_CATEGORY, COG20_PATHWAY, KEGG_Module, KEGG_Class                                                               
Genomes storage ..............................: Initialized (storage hash: hash9bb588f0)                                                                                                                
Num genomes in storage .......................: 59
Num genomes will be used .....................: 59
Pan database .................................: A new database, /home/genomics/mhannaert/anvio_visualisatie/reformatted/anvio_vis_pan/anvio_vis_pan-PAN.db, has been created.                           
Exclude partial gene calls ...................: False

AA sequences FASTA ...........................: /home/genomics/mhannaert/anvio_visualisatie/reformatted/anvio_vis_pan/combined-aas.fa                                                                   

Num AA sequences reported ....................: 279,034
Num excluded gene calls ......................: 0
Unique AA sequences FASTA ....................: /home/genomics/mhannaert/anvio_visualisatie/reformatted/anvio_vis_pan/combined-aas.fa.unique                                                            

DIAMOND MAKEDB
===============================================
Diamond search DB ............................: /home/genomics/mhannaert/anvio_visualisatie/reformatted/anvio_vis_pan/combined-aas.fa.unique.dmnd                                                       

DIAMOND BLASTP
===============================================
Additional params for blastp .................: --masking 0
Search results ...............................: /home/genomics/mhannaert/anvio_visualisatie/reformatted/anvio_vis_pan/diamond-search-results.txt                                                        

DIAMOND VIEW
===============================================
Diamond un-uniqued tabular output file .......: /home/genomics/mhannaert/anvio_visualisatie/reformatted/anvio_vis_pan/diamond-search-results.txt                                                        

MCL INPUT
===============================================
Min percent identity .........................: 0.0                                                                                                                                                     
Minbit .......................................: 0.5
Filtered search results ......................: 15,896,679 edges stored                                                                                                                                 
MCL input ....................................: /home/genomics/mhannaert/anvio_visualisatie/reformatted/anvio_vis_pan/mcl-input.txt

MCL
===============================================
MCL inflation ................................: 2.0
MCL output ...................................: /home/genomics/mhannaert/anvio_visualisatie/reformatted/anvio_vis_pan/mcl-clusters.txt                                                                  
Number of MCL clusters .......................: 11,706
                                                                                                                                                                                                        
CITATION
===============================================
The workflow you are using will likely use 'muscle' by Edgar,
doi:10.1093/nar/gkh340 (http://www.drive5.com/muscle) to align your sequences.
If you publish your findings, please do not forget to properly credit this tool.

* Your pangenome is ready with a total of 11,706 gene clusters across 59 genomes 🎉                                                                                                                     

--exclude-partial-gene-calls: command not found
````

Now I can visualize it by the following command: 
````
anvi-display-pan -g GENOMES.db \
                 -p anvio_vis_pan/anvio_vis_pan-PAN.db
````
I did this in a extern bureaublad 
but I got a weird looking interface, not the page that normally has to open. 
It got the error "bad HTML" -> the problem was that the chrome browser in the extern bureaublad 

I got a link and when I copy paste this in the chrome in the extern bureablad then i worked 

I got the graph and changed the items order to frequency 

now I performd the following command for performing anvi-compute-genome-similarity, which uses various similarity metrics such as PyANI to compute average nucleotide identity across your genomes, and sourmash to compute mash distance across your genomes. It expects any combination of external genome files, internal genome files, or a fasta text file that points to the paths of FASTA files
````
anvi-compute-genome-similarity --external-genomes external-genomes.txt \
                               --program pyANI \
                               --output-dir ANI \
                               --num-threads 6 \
                               --pan-db anvio_vis_pan/anvio_vis_pan-PAN.db 
````

then I will reload the avio graph that is open, this will add to the "layers" tab. 

I stopped it, because it is a beter option to use fastANI then pyANI 
So I started it again in a tmux session: 
````
anvi-compute-genome-similarity --external-genomes external-genomes.txt \
                               --program fastANI \
                               --output-dir ANI \
                               --num-threads 6 \
                               --pan-db anvio_vis_pan/anvio_vis_pan-PAN.db 
````
This was a lot faster, output: 
````
CITATION
===============================================
Anvi'o will use 'fastANI' by Jain et al. (DOI: 10.1038/s41467-018-07641-9) to
compute ANI. If you publish your findings, please do not forget to properly
credit their work.

[fastANI] Kmer size ..........................: 16                                                                                                                                     [fastANI] Fragment length ....................: 3,000
[fastANI] Min fraction of alignment ..........: 0.25
[fastANI] Num threads to use .................: 6
[fastANI] Log file path ......................: /tmp/tmpscn545ak

                                                                                                                                                                                       ANI RESULTS
===============================================
* Matrix and clustering of 'ani' written to output directory
* Matrix and clustering of 'alignment fraction' written to output directory
* Matrix and clustering of 'mapping fragments' written to output directory
* Matrix and clustering of 'total fragments' written to output directory

MISC DATA MAGIC FOR YOUR PAN DB
===============================================
* Additional data and order for ANI ani are now in pan db                                                                                                                              * Additional data and order for ANI alignment fraction are now in pan db                                                                                                               * Additional data and order for ANI mapping fragments are now in pan db                                                                                                                * Additional data and order for ANI total fragments are now in pan db

✓ anvi-compute-genome-similarity took 0:09:28.442517
````
So now I went again to the external bureaublad, and did:
````
anvi-display-pan -g GENOMES.db \
                 -p anvio_vis_pan/anvio_vis_pan-PAN.db
````
This added the extra option to the layer, so the computing worked 

I made two bins, I saved this state in "Bins" 

I wanted to open these bins again, but they weren't saved appernetly

the error that I made was that I needed to click "store bin collection" 

for adding the ANI plot to the graph, I needed to click exp. "ANI_mapping_fragments" and then redraw 

this added the ANI for mapping to my graph. 

The coloring of the lines: 
In the pangenome manual it looked like I had to split it before I could color it that way, so I performd the following command: 
````
anvi-split -p anvio_vis_pan/anvio_vis_pan-PAN.db \
           -g GENOMES.db \
           -C default \
           -o SPLIT_PANs
````
This step didn't work but also wasn't needed. So I didn't look further into it. 

To color these specific layers, I just have to select: In main all the genes or the genes of intereset and color them by clicking on them. 

I saved my last state with al the colors, result from this visualisation can be found in my Onenote on page 02/05/2024. 

