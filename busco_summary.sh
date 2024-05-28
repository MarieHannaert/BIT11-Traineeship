#!/bin/bash
# this script is made for performing the summary of the busco results. 
#This script is based on the illuminapipeline script

#PLOT SUMMARY of busco
mkdir -p "$1"/busco_summaries
echo "making summary busco" 
cp "$2" "$1"/busco_summaries
cd "$1"/busco_summaries/ 
#to generate a summary plot in PNG
#generate_plot.py -wd .


for i in $(seq 1 15 $(ls -1 | wc -l)); do
  echo "Verwerking van bestanden $i tot $((i+14))"
  mkdir -p part_"$i-$((i+14))"
  ls -1 | tail -n +$i | head -15 | while read file; do
    echo "Verwerking van bestand: $file"
    mv "$file" part_"$i-$((i+14))"
  done
  generate_plot.py -wd part_"$i-$((i+14))"
done

cd ../..
rm -dr busco_downloads