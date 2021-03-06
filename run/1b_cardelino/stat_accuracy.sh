#!/bin/bash
#Aim: to compare benchmark results of mode1b (well-based dataset with 
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

run=1b_cardelino
bcfR_dir=$RES_DIR/$run/run/bcftools-R_1_8
bcfT_dir=$RES_DIR/$run/run/bcftools-T_1_8
cspR_dir=$RES_DIR/$run/run/cellsnp-lite-R_1_8
cspT_dir=$RES_DIR/$run/run/cellsnp-lite-T_1_8
pycsp_dir=$RES_DIR/$run/run/cellSNP_1_8
snp=$DATA_DIR/snp/genome1K.phase3.SNP_AF5e2.chr1toX.hg19.snp.uniq.vcf.gz
util_dir=$work_dir/../utils
out_dir=$RES_DIR/$run/accuracy
if [ ! -d "$out_dir" ]; then mkdir -p $out_dir; fi
echo "[I::$prog] Analysis results of run '$run' and output to '$out_dir' ..."

set -x

# check if results of different runs for each tool are the same
# (should be the same)
$util_dir/diff_runs.sh bcftools-R $RES_DIR/$run/run
$util_dir/diff_runs.sh bcftools-T $RES_DIR/$run/run
$util_dir/diff_runs.sh cellSNP $RES_DIR/$run/run
$util_dir/diff_runs.sh cellsnp-lite-R $RES_DIR/$run/run
$util_dir/diff_runs.sh cellsnp-lite-T $RES_DIR/$run/run

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

bcfR_depth=$out_dir/bcftools-R.allele.depth.sort.tsv
vcf2depth  bcftools  $bcfR_dir/bcftools.vcf.gz  $bcfR_depth

bcfT_depth=$out_dir/bcftools-T.allele.depth.sort.tsv
vcf2depth  bcftools  $bcfT_dir/bcftools.vcf.gz  $bcfT_depth

cspR_depth=$out_dir/cellsnp-lite-R.allele.depth.sort.tsv
vcf2depth  cellsnp-lite  $cspR_dir/cellSNP.cells.vcf.gz  $cspR_depth

cspT_depth=$out_dir/cellsnp-lite-T.allele.depth.sort.tsv
vcf2depth  cellsnp-lite  $cspT_dir/cellSNP.cells.vcf.gz  $cspT_depth

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

diff_modes  bcftools-R  $bcfR_depth  bcftools-T  $bcfT_depth
diff_modes  cellsnp-lite-R  $cspR_depth  cellsnp-lite-T  $cspT_depth
diff_modes  bcftools-R  $bcfR_depth  cellsnp-lite-R  $cspR_depth
diff_modes  bcftools-T  $bcfT_depth  cellsnp-lite-T  $cspT_depth

echo "[I::$prog] Done!"

