#!/bin/bash
#Aim: to benchmark mode1a (droplet-based dataset with given SNPs)
#  on souporcell dataset using 3 tools: cellSNP, cellsnp-lite (-R/-T)
#  and vartrix
#Dependency: /usr/bin/time

set -e
set -o pipefail

if [ $# -lt 2 ]; then
  echo "" >&2
  echo "This script is aimed to benchmark mode1a (droplet-based dataset with given" >&2
  echo "SNPs) on souporcell dataset using 3 tools: cellSNP, cellsnp-lite (-R/-T)" >&2
  echo "and vartrix." >&2
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

run=1a_souporcell
util_dir=$work_dir/../utils
out_dir=$RES_DIR/$run/run
if [ ! -d "$out_dir" ]; then mkdir -p $out_dir; fi
echo "[I::$prog] Benchmark $run and output to '$out_dir' ..."

bam=$DATA_DIR/souporcell/soupc.bam
barcode=$DATA_DIR/souporcell/soupc.barcodes.tsv
snp=$DATA_DIR/snp/genome1K.phase3.SNP_AF5e2.chr1toX.hg19.snp.uniq.vcf.gz
fasta=$DATA_DIR/fasta/cellranger.hg19.3.0.0.fa
cell_tag=CB
umi_tag=UB
min_mapq=20
min_count=1
min_maf=0
min_len=0

set -x

# run cellSNP
res_dir=$out_dir/cellSNP_${i}_$n
if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
echo "[I::$prog] cellSNP (repeat=$i; ncores=$n) to '$res_dir' ..."
/usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
  $BIN_DIR/cellSNP             \
    -s $bam                     \
    -b $barcode                \
    -R $snp                    \
    -O $res_dir                \
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

# run cellsnp-lite (-R/-T)
for opt in -R -T; do
  res_dir=$out_dir/cellsnp-lite${opt}_${i}_$n
  if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
  echo "[I::$prog] cellsnp-lite$opt (repeat=$i; ncores=$n) to '$res_dir' ..."
  /usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
    $BIN_DIR/cellsnp-lite         \
      -s $bam                     \
      -b $barcode                \
      $opt $snp                   \
      -O $res_dir                \
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
  > $res_dir/run.out 2> $res_dir/run.err
  sleep 5
done

# run vartrix
res_dir=$out_dir/vartrix_${i}_$n
if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
echo "[I::$prog] vartrix (repeat=$i; ncores=$n) to '$res_dir' ..."
/usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
  $BIN_DIR/vartrix         \
    -b $bam                    \
    -c $barcode                \
    -v $snp                    \
    --fasta $fasta             \
    --ref-matrix $res_dir/ref.mtx          \
    --out-matrix $res_dir/alt.mtx          \
    --out-variants $res_dir/variants.tsv   \
    --threads $n               \
    --bam-tag $cell_tag        \
    --primary-alignments       \
    --umi                      \
    --mapq $min_mapq           \
    --scoring-method coverage  \
> $res_dir/run.out 2> $res_dir/run.err    

echo "[I::$prog] Done!"

