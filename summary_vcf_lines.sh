#!/bin/bash
# This script will create a muliple vcf file with only the last lines of the VCF files. 

DIR="$1"
OUT="$(pwd)"
cd "$DIR"

touch "$OUT"/multiple_vcf.vcf

for sample in $(ls -d "$DIR"/*); do
    cat "$sample"/snps.vcf | grep -v '^##'  >> "$OUT"/multiple_vcf.vcf
done