# Bash script to loop over a folder with Illumina files ending in _{1,2}.fq.gz files
# Steve Baeyen (ILVO), 2024

#make a directory trimmed

mkdir trimmed_dup

#loop over read files

for g in `ls *_1.fq.gz | awk 'BEGIN{FS="_1.fq.gz"}{print $1}'`
do
    echo "Working on trimming genome $g with fastp"
    fastp --dedup -w 16 -i "$g"_1.fq.gz -I "$g"_2.fq.gz -o ./trimmed_dup/"$g"_1.fq.gz -O ./trimmed_dup/"$g"_2.fq.gz --detect_adapter_for_pe
done
echo
echo "Finished trimming"
