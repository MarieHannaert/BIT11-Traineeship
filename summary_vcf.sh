#!/bin/bash
# This script will create a muliple vcf file with all the info of the vcf files. 

DIR="$1"
OUT="$(pwd)"
cd "$DIR"

touch "$OUT"/multiple_vcf.vcf

for file in $(find -type f -name "snps.vcf"); do
    cat "$DIR"/"$file" >> "$OUT"/multiple_vcf.vcf
done


