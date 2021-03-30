#!/bin/bash
#Aim: to compare results of mode2a, mode2b + mode1a, 
#  common_SNP + mode1a on souporcell dataset:
#  - count total and shared SNPs
#  - compare matrix of allele depths

set -e
set -o pipefail

work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`

if [ -z "$BIN_DIR" ] || [ -z "$DATA_DIR" ] || [ -z "$RES_DIR" ]; then 
  source $work_dir/../../config.sh > /dev/null
fi

set -u

run=2a_souporcell
dir_2a=$RES_DIR/$run/run/2a_1_16
dir_2b1a=$RES_DIR/$run/run/2b-1a_1_16
dir_csnp1a=$RES_DIR/$run/run/cSNP-1a_1_16
snp=$DATA_DIR/snp/genome1K.phase3.SNP_AF5e2.chr1toX.hg19.snp.uniq.vcf.gz
util_dir=$work_dir/../utils
out_dir=$RES_DIR/$run/accuracy
if [ ! -d "$out_dir" ]; then mkdir -p $out_dir; fi
echo "[I::$prog] Analysis results of run '$run' and output to '$out_dir' ..."

set -x

# count total SNPs
echo "[I::$prog] total SNP of mode2a '$dir_2a/cellSNP.base.vcf.gz' is"
$BIN_DIR/bcftools view $dir_2a/cellSNP.base.vcf.gz | grep -v '^#' | wc -l

echo "[I::$prog] total SNP of mode2b + mode1a '$dir_2b1a/cellSNP.base.vcf.gz' is" 
$BIN_DIR/bcftools view $dir_2b1a/cellSNP.base.vcf.gz | grep -v '^#' | wc -l

echo "[I::$prog] total SNP of common_SNP + mode1a '$dir_csnp1a/cellSNP.base.vcf.gz' is" 
$BIN_DIR/bcftools view $dir_csnp1a/cellSNP.base.vcf.gz | grep -v '^#' | wc -l

function compare_modes() {
  local mode1=$1
  local dir1=$2
  local mode2=$3
  local dir2=$4
  local res_dir=$5

  # intersect SNPs
  local vcf12=$res_dir/${mode1}.${mode2}.cells.vcf.gz
  $BIN_DIR/bcftools view -Oz -T $dir2/cellSNP.base.vcf.gz \
    $dir1/cellSNP.cells.vcf.gz > $vcf12
  echo "[I::$prog] shared SNP of mode$mode1 with mode$mode2 is"
  $BIN_DIR/bcftools view $vcf12 | grep -v '^#' | wc -l

  local vcf21=$res_dir/${mode2}.${mode1}.cells.vcf.gz
  $BIN_DIR/bcftools view -Oz -T $dir1/cellSNP.base.vcf.gz \
    $dir2/cellSNP.cells.vcf.gz > $vcf21
  echo "[I::$prog] shared SNP of mode$mode2 with mode$mode1 is"
  $BIN_DIR/bcftools view $vcf21 | grep -v '^#' | wc -l

  # extract allele depth from vcf of shared SNPs
  local depth12=$res_dir/${mode1}.${mode2}.allele.depth.tsv
  $BIN_DIR/python $util_dir/csp2depth.py \
    --vcf $vcf12    \
    --countN        \
    --outfile $depth12

  local depth21=$res_dir/${mode2}.${mode1}.allele.depth.tsv
  $BIN_DIR/python $util_dir/csp2depth.py \
    --vcf $vcf21    \
    --countN        \
    --outfile $depth21

  # diff the two allele-depth files
  set +e
  diff $depth12 $depth21 &> $res_dir/diff.allele.depth.${mode1}.${mode2}.log 
  if [ $? -eq 0 ]; then
    echo "[I::$prog] allele depth files '$depth12' of mode$mode1 and \
                     '$depth21' of mode$mode2 are totally the same."
  else
    echo "[W::$prog] allele depth files '$depth12' of mode$mode1 and \
                     '$depth21' of mode$mode2 are different."
  fi
  set -e
}

# compare SNPs between mode2a and `mode2b + mode1a`
dir_2a_2b1a=$out_dir/2a-2b1a
if [ ! -d "$dir_2a_2b1a" ]; then mkdir -p $dir_2a_2b1a; fi
compare_modes  2a  $dir_2a  2b-1a  $dir_2b1a  $dir_2a_2b1a

# compare SNPs between mode2a and `common_SNP + mode1a`
dir_2a_csnp1a=$out_dir/2a-cSNP1a
if [ ! -d "$dir_2a_csnp1a" ]; then mkdir -p $dir_2a_csnp1a; fi

## Intersect SNPs of mode2a with common_SNPs used by mode1a.
## Here use cellSNP.base.vcf.gz and cellSNP.cells.vcf.gz as 
## the compare_modes() function would use these filenames.
echo "[I::$prog] intersect SNPs of mode2a with common_SNPs used by mode1a \
                 and output to '$dir_2a_csnp1a/cellSNP.base.vcf.gz' & \
                 '$dir_2a_csnp1a/cellSNP.cells.vcf.gz'"
$BIN_DIR/bcftools view -Oz -T $snp $dir_2a/cellSNP.base.vcf.gz \
  > $dir_2a_csnp1a/cellSNP.base.vcf.gz
$BIN_DIR/bcftools view -Oz -T $snp $dir_2a/cellSNP.cells.vcf.gz \
  > $dir_2a_csnp1a/cellSNP.cells.vcf.gz

compare_modes  2a  $dir_2a_csnp1a  cSNP-1a  $dir_csnp1a  $dir_2a_csnp1a

echo "[I::$prog] Done!"

