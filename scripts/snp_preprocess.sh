#!/bin/bash 
#Aim: to filter SNPs of type indel, multi-allele, and duplicates
#Dependency: bcftools and bgzip (both tested on v1.10.2)

set -eux

in=genome1K.phase3.SNP_AF5e2.chr1toX.hg19.vcf.gz
out=genome1K.phase3.SNP_AF5e2.chr1toX.hg19.snp.uniq.vcf.gz
work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`

echo "[I::$prog] total SNPs of input '$in'"
bcftools view $in | grep -v '^#' | wc -l

tmp=${out}.tmp

# print header
bcftools view $in | sed '/^#/!q' | grep '^#' > $tmp

# filter SNPs of type indel, multi-allele, and duplicates.
# note that the input file has been sorted so no need to 
#   sort again below.
bcftools view $in | \
  awk '!/^#/' | \
  awk 'length($4) == 1 && length($5) == 1' | \
  awk '{
    k=$1">"$2">"$4">"$5; 
    if(k != k0) { print; k0 = k; }
  }' >> $tmp

# bgzip file and then index
cat $tmp | bgzip -c > $out
bcftools index $out
rm $tmp

echo "[I::$prog] total SNPs of output '$out'"
bcftools view $out | grep -v '^#' | wc -l

