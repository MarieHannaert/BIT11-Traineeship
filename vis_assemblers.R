#visualization of the comparison of three different assemblers in terms of the number of contigs and N50
#install.packages("beeswarm")
#making one figure with the two boxplots and two beeswarm plots
par(mfrow = c(2,2))
#the two boxplots
boxplot(contigs ~ assembler_type, data = quast_summary_table_complete, col= c("#3FA0FF", "#FFE099", "#F76D5E"))
boxplot(N50 ~ assembler_type, data = quast_summary_table_complete, col= c("#3FA0FF", "#FFE099", "#F76D5E"))
#the two beeswarm plots
library(beeswarm)
beeswarm(contigs ~ assembler_type, data = quast_summary_table_complete,
         pch = 19, 
         col = c("#3FA0FF", "#FFE099", "#F76D5E"))
beeswarm(N50 ~ assembler_type, data = quast_summary_table_complete,
         pch = 19, 
         col = c("#3FA0FF", "#FFE099", "#F76D5E"))
