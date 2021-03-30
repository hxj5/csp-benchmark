#!/bin/bash
#Aim: to benchmark mode2b (bulk mode without given SNPs)
#  on souporcell dataset using 3 tools: cellSNP, cellsnp-lite and freebayes
#Dependency: /usr/bin/time

set -e
set -o pipefail

if [ $# -lt 2 ]; then
  echo "" >&2
  echo "This script is aimed to benchmark mode2b (bulk mode without given SNPs) on" >&2
  echo "souporcell dataset using 3 tools: cellSNP, cellsnp-lite and freebayes." >&2
  echo "" >&2
  echo "Usage: $0 <repeat id> <ncore>" >&2
  echo "" >&2
  echo "<repeat id> i-th repeat, start from 1" >&2
  echo "<ncore> number of cores" >&2
  echo "" >&2
  exit 1
fi
i=$1     # i-th repeat
n=$2     # number of cores

work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`

if [ -z "$BIN_DIR" ] || [ -z "$DATA_DIR" ] || [ -z "$RES_DIR" ]; then 
  source $work_dir/../../config.sh > /dev/null
fi

set -u

run=2b_souporcell
util_dir=$work_dir/../utils
out_dir=$RES_DIR/$run/run
if [ ! -d "$out_dir" ]; then mkdir -p $out_dir; fi
echo "[I::$prog] Benchmark $run and output to '$out_dir' ..."

bam=$DATA_DIR/souporcell/soupc.bam
fasta=$DATA_DIR/fasta/cellranger.hg19.3.0.0.fa
cell_tag=None
umi_tag=None
min_mapq=20
min_count=1
min_maf=0
min_len=0

set -x

chroms="`seq 1 22` X Y"
chroms=`echo $chroms | tr ' ' ','`

# run cellSNP
res_dir=$out_dir/cellSNP_${i}_$n
if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
echo "[I::$prog] cellSNP (repeat=$i; ncores=$n) to '$res_dir' ..."
/usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
  $BIN_DIR/cellSNP             \
    -s $bam                     \
    -O $res_dir                \
    --chrom $chroms            \
    -p $n                      \
    --cellTAG $cell_tag       \
    --UMItag $umi_tag          \
    --minCOUNT $min_count        \
    --minMAF $min_maf         \
    --minLEN $min_len          \
    --minMAPQ $min_mapq        \
    --maxFLAG 4096             \
> $res_dir/run.out 2> $res_dir/run.err
sleep 5

# run cellsnp-lite
res_dir=$out_dir/cellsnp-lite_${i}_$n
if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
echo "[I::$prog] cellsnp-lite (repeat=$i; ncores=$n) to '$res_dir' ..."
/usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
  $BIN_DIR/cellsnp-lite         \
    -s $bam                     \
    -O $res_dir                \
    --chrom $chroms            \
    -p $n                      \
    --cellTAG $cell_tag       \
    --UMItag $umi_tag          \
    --minCOUNT $min_count        \
    --minMAF $min_maf         \
    --minLEN $min_len          \
    --minMAPQ $min_mapq        \
    --exclFLAG 772             \
    --inclFLAG 0               \
    --gzip                    \
    --genotype                \
> $res_dir/run.out 2> $res_dir/run.err
sleep 5

# run freebayes
res_dir=$out_dir/freebayes_${i}_$n
if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
echo "[I::$prog] freebayes (repeat=$i; ncores=$n) to '$res_dir' ..."
export PATH=$BIN_DIR:$PATH
region=$res_dir/freebayes.region.tsv
fasta_generate_regions.py $fasta 100000 > $region
/usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
  freebayes-parallel \
    $region            \
    $n                 \
    -f $fasta                     \
    --genotype-qualities          \
    --use-duplicate-reads         \
    $bam                          \
    > $res_dir/freebayes.raw.vcf \
2> $res_dir/run.err

echo "[I::$prog] Done!"

