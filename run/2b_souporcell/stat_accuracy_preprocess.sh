#!/bin/bash
#Aim: to proprocess genotype-vcf of cellsnp-lite and freebayes to
#  perform basic statistics and output

set -e
set -o pipefail

if [ $# -lt 4 ]; then
  echo "" >&2
  echo "This script is aimed to proprocess genotype-vcf of cellsnp-lite and freebayes" >&2
  echo "to perform basic statistics and output" >&2
  echo "" >&2
  echo "Usage: $0 <cellsnp_vcf> <freebayes_vcf> <array_vcf> <out_dir>" >&2
  echo "" >&2
  echo "<cellsnp_vcf> the vcf containing genotypes called by cellsnp-lite" >&2
  echo "<freebayes_vcf> the vcf containing genotypes called by freebayes" >&2
  echo "<array_vcf> the vcf containing genotypes called by array" >&2
  echo "<out_dir> output dir" >&2
  echo "" >&2
  exit 1
fi
csp_vcf=$1
fby_vcf0=$2
arr_vcf=$3
out_dir=$4

work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`
util_dir=$work_dir/../utils

if [ -z "$BIN_DIR" ]; then 
  source $work_dir/../../config.sh > /dev/null
fi

set -ux

function count_vcf() {
  $BIN_DIR/bcftools view $1 | grep -v '^#' | wc -l
  $BIN_DIR/bcftools query -f '[%GT]\n' $1 | \
    awk '$1 == "0/0" || $1 == "1/1"' | wc -l
  $BIN_DIR/bcftools query -f '[%GT]\n' $1 | \
    awk '$1 == "0/1" || $1 == "1/0"' | wc -l
}

function count_query() {
  ##query-tsv header:
  ##  chrom  pos  sort_ref_alt_app  GT_app  sort_TGT_app  $gq_pre  GQ
  ##  sort_ref_alt_array  GT_array  sort_TGT_array
  cat $1 | grep -v '^#' | wc -l
  cat $1 | grep -v '^#' | awk '$4 == "0/0" || $4 == "1/1"' | wc -l
  cat $1 | grep -v '^#' | awk '$4 == "0/1" || $4 == "1/0"' | wc -l
  cat $1 | grep -v '^#' | awk '$9 == "0/0" || $9 == "1/1"' | wc -l
  cat $1 | grep -v '^#' | awk '$9 == "0/1" || $9 == "1/0"' | wc -l
}

function merge_app_array() {
  local app=$1
  local app_vcf=$2

  echo "[I::$prog] $app preprocess '$app_vcf' with '$arr_vcf' and output to '$out_dir' ..."

  # intersect app vcf with array vcf
  local app_shared=$out_dir/${app}.intersect.array.vcf.gz
  $BIN_DIR/bcftools view -T $arr_vcf -Oz $app_vcf > $app_shared
  
  # intersect array vcf with app vcf
  local arr_shared=$out_dir/array.intersect.${app}.vcf.gz
  $BIN_DIR/bcftools view -T $app_shared -Oz $arr_vcf > $arr_shared
  
  # extract info from app_shared vcf
  local app_query=$out_dir/${app}.array.query.sort.tsv
  local app_query0=${app_query}.tmp
  if [ "$app" == "cellsnp-lite" ]; then
    $BIN_DIR/bcftools query -f \
      '%CHROM\t%POS\t%REF/%ALT[\t%GT\t%TGT\t%PL]\n' $app_shared | \
    gawk '{
      n = split($NF, a, ",");
      if (n != 3) exit 1;
      asort(a);
      GQ = a[2] - a[1];
      printf("%s\t%f\n", $0, GQ);
    }' > $app_query0
  elif [ "$app" == "freebayes" ]; then
    $BIN_DIR/bcftools query -f \
      '%CHROM\t%POS\t%REF/%ALT[\t%GT\t%TGT\t%GL]\n' $app_shared | \
    gawk '{
      n = split($NF, a, ",");
      if (n != 3) exit 1;
      asort(a);
      GQ = 10 * (a[3] - a[2]);
      printf("%s\t%f\n", $0, GQ);
    }' > $app_query0
  else
    echo "[E::$prog] wrong app '$app'" >&2
    exit 3
  fi
  
  # sort 1) chrom+pos; 2) REF and ALT; 3) two alleles of TGT
  cat $app_query0 | \
  sort -k1,1V -k2,2n | \
  gawk '
    BEGIN {OFS = "\t"}
    {
      split($3, ref_alt, "/");
      asort(ref_alt);
      $3 = ref_alt[1]"/"ref_alt[2];
      split($5, tgt, "/");
      asort(tgt);
      $5 = tgt[1]"/"tgt[2];
      print;
    }' > $app_query
  rm $app_query0
  
  # extract info from arr_shared vcf
  # and sort 1) chrom+pos; 2) REF and ALT; 3) two alleles of TGT
  local arr_query=$out_dir/array.${app}.query.sort.tsv
  $BIN_DIR/bcftools query -f \
    '%CHROM\t%POS\t%REF/%ALT[\t%GT\t%TGT]\n' $arr_shared | \
  sort -k1,1V -k2,2n | \
  gawk '
  BEGIN {OFS = "\t"}
  {
    split($3, ref_alt, "/");
    asort(ref_alt);
    $3 = ref_alt[1]"/"ref_alt[2];
    split($5, tgt, "/");
    asort(tgt);
    $5 = tgt[1]"/"tgt[2];
    print;
  }' > $arr_query
  
  # merge app tsv and array tsv
  # (firstly check if the two tsv files have the same chrom+pos)
  diff <(awk '{print $1, $2}' $app_query) \
       <(awk '{print $1, $2}' $arr_query)
  
  paste $app_query \
    <(awk '{printf("%s\t%s\t%s\n", $3, $4, $5)}' $arr_query) \
    > $app_query0
  
  local gq_pre=GL
  if [ "$app" == cellsnp-lite ]; then 
    gq_pre=PL
  fi
  echo -e "#chrom\tpos\tsort_ref_alt_app\tGT_app\tsort_TGT_app\t$gq_pre\tGQ\tsort_ref_alt_array\tGT_array\tsort_TGT_array" > $app_query
  cat $app_query0 >> $app_query

  # count shared SNPs
  echo "[I::$prog] SNPs shared by ${app} and array '$app_query' in the order of All/Hom_app/Het_app/Hom_array/Het_array:"
  count_query $app_query
  
  rm $app_query0
  rm $arr_query
}

# count SNPs in vcf
echo "[I::$prog] SNPs of cellsnp-lite vcf '$csp_vcf' in the order of All/Hom/Het:"
count_vcf $csp_vcf

echo "[I::$prog] total SNPs of raw freebayes vcf '$fby_vcf0':"
$BIN_DIR/bcftools view $fby_vcf0 | grep -v '^#' | wc -l

## filter raw freebayes vcf, keep only SNPs with LEN(REF) = 1 && LEN(ALT) = 1.
fby_vcf=$out_dir/freebayes.snp.vcf.gz
$BIN_DIR/bcftools view $fby_vcf0 | \
  awk '$0 ~ /^#/ || (length($4) == 1 && length($5) == 1)' | \
  $BIN_DIR/bgzip -c > $fby_vcf
$BIN_DIR/bcftools index $fby_vcf

echo "[I::$prog] SNPs of post-filtering freebayes vcf '$fby_vcf' in the order of All/Hom/Het:"
count_vcf $fby_vcf

echo "[I::$prog] SNPs of array vcf '$arr_vcf' in the order of All/Hom/Het:"
count_vcf $arr_vcf

# extract/query info from app vcf & array vcf to tsv files and 
# merge SNPs in the tsv files based on chrom+pos
merge_app_array cellsnp-lite $csp_vcf
merge_app_array freebayes $fby_vcf

# get shared SNPs (chrom+pos) of celsnp, freebayes and array
csp_query=$out_dir/cellsnp-lite.array.query.sort.tsv    # from last step
fby_query=$out_dir/freebayes.array.query.sort.tsv       # from last step

csp_query3=$out_dir/cellsnp-lite.array.freebayes.query.tsv
awk 'ARGIND == 1 {a[$1">"$2]=1; next} ARGIND == 2 && a[$1">"$2]' \
  $fby_query $csp_query > $csp_query3
echo "[I::$prog] SNPs shared by cellsnp-lite, freebayes, and array '$csp_query3' \
                 in the order of All/Hom_app/Het_app/Hom_array/Het_array:"
count_query $csp_query3

fby_query3=$out_dir/freebayes.array.cellsnp-lite.query.tsv
awk 'ARGIND == 1 {a[$1">"$2]=1; next} ARGIND == 2 && a[$1">"$2]' \
  $csp_query $fby_query > $fby_query3
echo "[I::$prog] SNPs shared by cellsnp-lite, freebayes, and array '$fby_query3' \
                 in the order of All/Hom_app/Het_app/Hom_array/Het_array:"
count_query $fby_query3

