#!/bin/bash
#Aim: to compare benchmark results of mode1a (droplet-based dataset with 
#  given SNPs) on demuxlet dataset:
#  - plot accuracy in terms of correlation and MAE between
#    cellsnp-lite (-R/-T) and vartrix

set -e
set -o pipefail

work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`

if [ -z "$BIN_DIR" ] || [ -z "$DATA_DIR" ] || [ -z "$RES_DIR" ]; then 
  source $work_dir/../../config.sh > /dev/null
fi

set -u

run=1a_demuxlet
cspR_dir=$RES_DIR/$run/run/cellsnp-lite-R_1_8
cspT_dir=$RES_DIR/$run/run/cellsnp-lite-T_1_8
vtx_dir=$RES_DIR/$run/run/vartrix_1_8
pycsp_dir=$RES_DIR/$run/run/cellSNP_1_8
snp=$DATA_DIR/snp/genome1K.phase3.SNP_AF5e2.chr1toX.hg19.snp.uniq.vcf.gz
util_dir=$work_dir/../utils
out_dir=$RES_DIR/$run/accuracy
if [ ! -d "$out_dir" ]; then mkdir -p $out_dir; fi
echo "[I::$prog] Analysis results of run '$run' and output to '$out_dir' ..."

set -x

# check if results of different runs for each tool are the same
# (should be the same)
$util_dir/diff_runs.sh cellSNP $RES_DIR/$run/run
$util_dir/diff_runs.sh cellsnp-lite-R $RES_DIR/$run/run
$util_dir/diff_runs.sh cellsnp-lite-T $RES_DIR/$run/run
$util_dir/diff_runs.sh vartrix $RES_DIR/$run/run

# check if cellsnp-lite-R and cellsnp-lite-T have the same output
# (should be the same)
diff <(zcat $cspR_dir/cellSNP.base.vcf.gz | grep -v '^#') \
     <(zcat $cspT_dir/cellSNP.base.vcf.gz | grep -v '^#')
diff $cspR_dir/cellSNP.tag.AD.mtx $cspT_dir/cellSNP.tag.AD.mtx
diff $cspR_dir/cellSNP.tag.DP.mtx $cspT_dir/cellSNP.tag.DP.mtx
diff $cspR_dir/cellSNP.tag.OTH.mtx $cspT_dir/cellSNP.tag.OTH.mtx

# get ref mtx for cellsnp-lite
csp_ref=$out_dir/cellSNP.tag.ref.mtx
$BIN_DIR/Rscript $util_dir/mtx_get_ref.r \
  --ad $cspR_dir/cellSNP.tag.AD.mtx \
  --dp $cspR_dir/cellSNP.tag.DP.mtx \
  -o $csp_ref

# compare vartrix variants with original input variants
# (should be the same)
diff <(cat $vtx_dir/variants.tsv | awk -F'_' '{printf("%s\t%s\n", $1, $2 + 1)}') \
     <(zcat $snp | grep -v '^#' | awk '{printf("%s\t%s\n", $1, $2)}')

# plot accuracy
$util_dir/accuracy.sh \
  --name1 cellsnp-lite     \
  --ref1 $csp_ref          \
  --alt1 $cspR_dir/cellSNP.tag.AD.mtx   \
  --variant1 $cspR_dir/cellSNP.base.vcf.gz  \
  --name2 vartrix           \
  --ref2 $vtx_dir/ref.mtx   \
  --alt2 $vtx_dir/alt.mtx   \
  --variant2 $snp           \
  -O $out_dir   

echo "[I::$prog] Done!"

