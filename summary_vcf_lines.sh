#!/bin/bash
# This script will create a muliple vcf file with only the last lines of the VCF files. 

DIR="$1"
OUT="$(pwd)"
cd "$DIR"

touch "$OUT"/multiple_vcf_lines.vcf

sample_list=$(ls | grep "GBBC_")
echo $sample_list

echo -e "##fileformat=VCFv4.2" >> "$OUT"/multiple_vcf_lines.vcf
echo -e "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t$sample_list" >> "$OUT"/multiple_vcf_lines.vcf

for sample in $(ls | grep "GBBC_"); do
    cat "$sample"/snps.vcf | grep -v '^#'  >> "$OUT"/multiple_vcf_lines.vcf
done