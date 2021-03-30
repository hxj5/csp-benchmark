#!/bin/bash
#Aim: to compare benchmark results of mode1a (droplet-based dataset with 
#  given SNPs) on souporcell dataset:
#  - plot efficiency in terms of time and memory usage for 
#    cellSNP, cellsnp-lite and vartrix

set -e
set -o pipefail

work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`

if [ -z "$BIN_DIR" ] || [ -z "$RES_DIR" ]; then 
  source $work_dir/../../config.sh > /dev/null
fi

set -u

run=1a_souporcell
util_dir=$work_dir/../utils
out_dir=$RES_DIR/$run/efficiency
if [ ! -d "$out_dir" ]; then mkdir -p $out_dir; fi
echo "[I::$prog] Analysis results of run '$run' and output to '$out_dir' ..."

set -x

# extract and merge efficiency files
perf=$out_dir/${run}.efficiency.tsv
$util_dir/efficiency_merge.sh $RES_DIR/$run/run $perf

# plot efficiency for all tools
$BIN_DIR/Rscript $util_dir/plot_efficiency.r \
  -i $perf \
  -o $out_dir/${run}.efficiency.cpu.summary.tsv \
  -f $out_dir/${run}.efficiency.cpu.tiff \
  --time cpu

$BIN_DIR/Rscript $util_dir/plot_efficiency.r \
  -i $perf \
  -o $out_dir/${run}.efficiency.wall.summary.tsv \
  -f $out_dir/${run}.efficiency.wall.tiff \
  --time wall 

echo "[I::$prog] Done!"

