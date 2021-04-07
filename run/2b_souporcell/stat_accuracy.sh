#!/bin/bash
#Aim: to compare benchmark results of mode2b (bulk mode without
#  given SNPs) on souporcell dataset:
#  - plot accuracy in terms of Precision-Recall Curve among
#    cellsnp-lite, freebayes and genotype-array

set -e
set -o pipefail

work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`

if [ -z "$BIN_DIR" ] || [ -z "$DATA_DIR" ] || [ -z "$RES_DIR" ]; then 
  source $work_dir/../../config.sh > /dev/null
fi

set -u

run=2b_souporcell
csp_vcf=$RES_DIR/$run/run/cellsnp-lite_1_8/cellSNP.cells.vcf.gz
fby_vcf=$RES_DIR/$run/run/freebayes_1_8/freebayes.raw.vcf
arr_vcf=$DATA_DIR/souporcell/soupc.gtarray.vcf.gz
util_dir=$work_dir/../utils
out_dir=$RES_DIR/$run/accuracy
if [ ! -d "$out_dir" ]; then mkdir -p $out_dir; fi
echo "[I::$prog] Analysis results of run '$run' and output to '$out_dir' ..."

set -x

# check if results of different runs for each tool are the same
# (should be the same)
$util_dir/diff_runs.sh cellSNP $RES_DIR/$run/run
$util_dir/diff_runs.sh cellsnp-lite $RES_DIR/$run/run
$util_dir/diff_runs.sh freebayes $RES_DIR/$run/run

# preprocess app vcf and array vcf to extract info from these files
# GQ is calculated in this step
pre_dir=$out_dir/preprocess
if [ ! -d "$pre_dir" ]; then mkdir -p $pre_dir; fi
$work_dir/stat_accuracy_preprocess.sh \
  $csp_vcf       \
  $fby_vcf       \
  $arr_vcf       \
  $pre_dir

## these files are generated during preprocessing
csp_query=$pre_dir/cellsnp-lite.array.query.sort.tsv    
fby_query=$pre_dir/freebayes.array.query.sort.tsv       
csp_query3=$pre_dir/cellsnp-lite.array.freebayes.query.tsv
fby_query3=$pre_dir/freebayes.array.cellsnp-lite.query.tsv

# plot Precision-Recall Curve for TGT of SNPs shared by app & array (chrom+pos)
function query2pr() {
  ## the two columns of the output precision.recall.tsv are
  ##   <int> sort_TGT_app == sort_TGT_array
  ##   <float> GQ
  cat $1 | grep -v '^#' | \
    awk '{printf("%d\t%s\n", $5 == $10, $7)}' \
    > $2
}

## PRCurve of cellsnp-lite & array
csp_pr=$out_dir/cellsnp-lite.array.precision.recall.tsv
query2pr $csp_query $csp_pr
$BIN_DIR/python $work_dir/stat_accuracy_PRCurve.py \
  --name1 cellsnp-lite     \
  --infile1 $csp_pr        \
  --outfig $out_dir/cellsnp-lite.array.precision.recall.tiff \
  --color red

## PRCurve of freebayes & array
fby_pr=$out_dir/freebayes.array.precision.recall.tsv
query2pr $fby_query $fby_pr
$BIN_DIR/python $work_dir/stat_accuracy_PRCurve.py \
  --name1 freebayes        \
  --infile1 $fby_pr        \
  --outfig $out_dir/freebayes.array.precision.recall.tiff  \
  --color blue

# plot Precision-Recall curve for TGT of SNPs shared by cellsnp-lite, freebayes
# and array (chrom+pos)
csp_pr3=$out_dir/cellsnp-lite.array.freebayes.precision.recall.tsv
fby_pr3=$out_dir/freebayes.array.cellsnp-lite.precision.recall.tsv
query2pr $csp_query3 $csp_pr3
query2pr $fby_query3 $fby_pr3
$BIN_DIR/python $work_dir/stat_accuracy_PRCurve.py \
  --name1 cellsnp-lite     \
  --infile1 $csp_pr3       \
  --name2 freebayes        \
  --infile2 $fby_pr3       \
  --outfig $out_dir/array.cellsnp-lite.freebayes.precision.recall.tiff

# plot Precision-Recall curve for TGT of Het SNPs shared by cellsnp-lite, 
# freebayes and array (chrom+pos)
csp_query3_het=$pre_dir/cellsnp-lite.array.freebayes.query.het.tsv
fby_query3_het=$pre_dir/freebayes.array.cellsnp-lite.query.het.tsv
cat $csp_query3 | awk 'NR == 1 || $9 == "0/1" || $9 == "1/0"' > $csp_query3_het
cat $fby_query3 | awk 'NR == 1 || $9 == "0/1" || $9 == "1/0"' > $fby_query3_het

csp_pr3_het=$out_dir/cellsnp-lite.array.freebayes.precision.recall.het.tsv
fby_pr3_het=$out_dir/freebayes.array.cellsnp-lite.precision.recall.het.tsv
query2pr $csp_query3_het $csp_pr3_het
query2pr $fby_query3_het $fby_pr3_het

$BIN_DIR/python $work_dir/stat_accuracy_PRCurve.py \
  --name1 cellsnp-lite     \
  --infile1 $csp_pr3_het       \
  --name2 freebayes        \
  --infile2 $fby_pr3_het       \
  --outfig $out_dir/array.cellsnp-lite.freebayes.precision.recall.het.tiff

echo "[I::$prog] Done!"

