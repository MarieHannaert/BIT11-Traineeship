#!/bin/bash
# This script performs the summary of the BUSCO results based on the Illuminapipeline script.

# Define the base directory and the file to copy
base_dir="$1"


# Ensure the base directory exists and copy the specified file into it
mkdir -p "$base_dir"
echo "Making summary BUSCO"
for file in $(find -type f -name "short_summary.specific.burkholderiales_odb10.*.txt"); do
  cp "$file" "$base_dir"
done



# Count the total number of files (excluding directories)
total_files=$(find "$base_dir" -maxdepth 1 -type f | wc -l)

# Loop over the files in increments of 15
for i in $(seq 1 15 $total_files); do
  echo "Processing files $i to $((i+14))"
  sub_dir_name="$base_dir/part_$i-$((i+14))"
  mkdir -p "$sub_dir_name"
  
  # Move the files to the subdirectory
  find "$base_dir" -maxdepth 1 -type f | tail -n +$i | head -15 | while read -r file; do
    echo "Processing file: $file"
    mv "$file" "$sub_dir_name/"
  done
  
  # Optionally, run a script in the new subdirectory
  generate_plot.py -wd "$sub_dir_name"
done

# Optionally, remove the busco_downloads directory if it exists
# rm -dr "$base_dir/busco_downloads"

echo "Files have been organized into subdirectories."




