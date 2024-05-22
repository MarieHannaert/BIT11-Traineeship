#!/usr/bin/env Rscript
#install.packages("beeswarm")
#adding the location argument for the quast summary table from the bash script
#the argument needs to be the path to the quast summary file
args <- commandArgs(trailingOnly = TRUE)
location <- args[1]

#reading in the data file from quast
quast_summary_table <- read.delim(location)
#quast_summary_table <- read.delim("/home/genomics/mhannaert/data/mini_testdata/gz_files/output_test4/06_quast/quast_summary_table.txt")

#open PNG file to save
png("beeswarm_vis_assemblies.png")

#making one figure with two beeswarm plots
par(mfrow = c(1,2))
library(beeswarm)
#beeswarm plot of contigs
beeswarm(quast_summary_table$contigs,
         pch = 19, ylab = "contigs",
         col = c("#3FA0FF", "#FFE099", "#F76D5E"))
#beeswarm plot of N50
beeswarm(quast_summary_table$N50,
         pch = 19, ylab = "N50",
         col = c("#3FA0FF", "#FFE099", "#F76D5E"))

#savind the figure that was made as a png 
dev.off()
