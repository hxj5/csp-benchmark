#!/bin/bash
#Aim: to compare benchmark results of mode2a (droplet-based dataset without
#  given SNPs) on souporcell dataset:
#  - plot efficiency in terms of time and memory usage for 
#     mode2a, mode2b + mode1a

set -e
set -o pipefail

work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`

if [ -z "$BIN_DIR" ] || [ -z "$RES_DIR" ]; then 
  source $work_dir/../../config.sh > /dev/null
fi

set -u

run=2a_souporcell
util_dir=$work_dir/../utils
out_dir=$RES_DIR/$run/efficiency
if [ ! -d "$out_dir" ]; then mkdir -p $out_dir; fi
echo "[I::$prog] Analysis results of run '$run' and output to '$out_dir' ..."

set -x

# extract and merge efficiency files
# Note that for 2b-1a, the RSS from memusg in run.err was
# incorrect, so use RSS from /usr/bin/time in run.err instead.
# (actually for 2b-1a, the RSS from memusg in 2b.err was right
# and almost the same with RSS from /usr/bin/time in either
# run.err or 2b.err. For convenience, using RSS from 
# /usr/bin/time in run.err is ok)
perf=$out_dir/${run}.efficiency.tsv
$util_dir/efficiency_merge.sh $RES_DIR/$run/run $perf /usr/bin/time

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

# details about mode2b + mode1a
## merge time and memory usage of mode2b and mode1a separately
function stat_usage() {
  local mode=$1
  local res_dir=$2
  local perf=$res_dir/${mode}.efficiency.tsv
  $util_dir/efficiency_merge.sh \
    $RES_DIR/$run/run  $perf    \
    memusg  ${mode}.err  ^2b-1a
  echo "[I::$prog] efficiency statistics for '$mode' '$perf' in the order of \
                   cpu_time_mean/wall_time_mean/memory_mean is"
  cat $perf | awk '{
    cpu += $4;
    wall += $5;
    mem += $6;
  } END {
    printf("%f %f %f\n", cpu/NR, wall/NR, mem/NR);
  }'
}

dir_2b1a=$out_dir/2b1a
if [ ! -d "$dir_2b1a" ]; then mkdir -p $dir_2b1a; fi
stat_usage  2b  $dir_2b1a
stat_usage  1a  $dir_2b1a

echo "[I::$prog] Done!"

