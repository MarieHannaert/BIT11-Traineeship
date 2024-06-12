#!/bin/bash
# This script performs the summary of the BUSCO results based on the Illumina pipeline script.

# Define the base directory and the file to copy
base_dir="$1"
mkdir -p "$base_dir"

for file in $( ls results/08_busco/*/ | grep "short_summary.specific.*_odb10.*.txt"); do
  cp results/08_busco/*/"$file" "$base_dir"
done

#total_count="$(ls results/busco_summary | wc -l)"
#echo $total_count

# Tel bij hoeveel bestanden we zitten
counter=0
batch_number=1

for file in "$base_dir"/*; do
  if [ -f "$file" ]; then
    # Als we aan het begin van een nieuwe batch zijn, maak een nieuwe map voor de batch
    if [ "$counter" -eq 0 ]; then
      huidige_doel_directory="$base_dir/batch_$batch_number"
      mkdir -p "$huidige_doel_directory"
      echo "made $huidige_doel_directory"
    fi

    mv "$file" "$huidige_doel_directory"
    ((counter++))
    
    # Als we 15 bestanden hebben gekopieerd, reset de teller en verhoog het batchnummer
    if [ "$counter" -eq 15 ]; then
      counter=0
      batch_number=$((batch_number + 1))
      echo "batch_number is now $batch_number"
    fi
  fi
done

for directory in $(ls "$base_dir"); do
    generate_plot.py -wd "$base_dir/$directory";
done 