#!/bin/bash
#Aim: to compare benchmark results of mode2b (well-based dataset without
#  given SNPs) on cardelino dataset:
#  - extract allele depth from vcf to create a SNP x Sample matrix
#    and compare the matrices

set -e
set -o pipefail

work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`

if [ -z "$BIN_DIR" ] || [ -z "$DATA_DIR" ] || [ -z "$RES_DIR" ]; then 
  source $work_dir/../../config.sh > /dev/null
fi

set -u

run=2b_cardelino
bcf2b_dir=$RES_DIR/$run/run/bcftools-2b_1_8
csp2b_dir=$RES_DIR/$run/run/cellsnp-lite-2b_1_8
snp=$DATA_DIR/snp/genome1K.phase3.SNP_AF5e2.chr1toX.hg19.snp.uniq.vcf.gz
util_dir=$work_dir/../utils
out_dir=$RES_DIR/$run/accuracy
if [ ! -d "$out_dir" ]; then mkdir -p $out_dir; fi
echo "[I::$prog] Analysis results of run '$run' and output to '$out_dir' ..."

set -x

# check if results of different runs for each tool are the same
# (should be the same)
$util_dir/diff_runs.sh bcftools-2b $RES_DIR/$run/run
$util_dir/diff_runs.sh cellsnp-lite-2b $RES_DIR/$run/run

# extract allele depth of A,C,G,T from vcf
# and sort by chrom+pos
function vcf2depth() {
  local tool=$1
  local vcf=$2
  local depth=$3
  echo "[I::$prog] '$tool' extract allele depth of A,C,G,T from '$vcf' then \
                   sort by chrom+pos and output to '$depth'"
  if [ "$tool" == "bcftools" ]; then
    $BIN_DIR/python $util_dir/bcf2depth.py \
      --vcf $vcf   \
      --outfile ${depth}.tmp
  else
    $BIN_DIR/python $util_dir/csp2depth.py \
      --vcf $vcf   \
      --outfile ${depth}.tmp
  fi
  cat ${depth}.tmp | sort -k1,1V -k2,2n > $depth
  rm ${depth}.tmp
}

# compare the depth files
function diff_modes() {
  local mode1=$1
  local depth1=$2
  local mode2=$3
  local depth2=$4
  set +e
  diff $depth1 $depth2 &> $out_dir/diff.allele.depth.${mode1}.${mode2}.log
  if [ $? -eq 0 ]; then
    echo "[I::$prog] allele depth files '$depth1' of $mode1 and \
                     '$depth2' of $mode2 are totally the same."
  else
    echo "[W::$prog] allele depth files '$depth1' of $mode1 and \
                     '$depth2' of $mode2 are different."
  fi
  set -e
}

# compare cellsnp-lite-2b and bcftools-2b
bcf2b_depth=$out_dir/bcftools-2b.allele.depth.sort.tsv
vcf2depth  bcftools  $bcf2b_dir/bcftools.vcf.gz  $bcf2b_depth

csp2b_depth=$out_dir/cellsnp-lite-2b.allele.depth.sort.tsv
vcf2depth  cellsnp-lite  $csp2b_dir/cellSNP.cells.vcf.gz  $csp2b_depth

diff_modes  bcftools-2b  $bcf2b_depth  cellsnp-lite-2b  $csp2b_depth

echo "[I::$prog] Done!"

