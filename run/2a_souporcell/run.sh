#!/bin/bash
#Aim: to benchmark mode2a, mode2b + mode1a, and
#  common_SNP + mode1a, on souporcell dataset
#Dependency: /usr/bin/time

set -e
set -o pipefail

if [ $# -lt 2 ]; then
  echo "" >&2
  echo "This script is aimed to benchmark mode2a, mode2b + mode1a, and" >&2
  echo "common_SNP + mode1a, on souporcell dataset." >&2
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

run=2a_souporcell
util_dir=$work_dir/../utils
out_dir=$RES_DIR/$run/run
if [ ! -d "$out_dir" ]; then mkdir -p $out_dir; fi
echo "[I::$prog] run cellsnp-lite $run and output to '$out_dir' ..."

bam=$DATA_DIR/souporcell/soupc.bam 
barcode=$DATA_DIR/souporcell/soupc.barcodes.tsv
snp=$DATA_DIR/snp/genome1K.phase3.SNP_AF5e2.chr1toX.hg19.snp.uniq.vcf.gz
min_mapq=20
min_count=100
min_maf=0.1
min_len=30

chroms="`seq 1 22` X"
chroms=`echo $chroms | tr ' ' ','`

set -x

# run mode 2a
res_dir=$out_dir/2a_${i}_$n
if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
echo "[I::$prog] mode 2a (repeat=$i; ncores=$n) to '$res_dir' ..."
/usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
  $BIN_DIR/cellsnp-lite         \
    -s $bam                    \
    -b $barcode                \
    -O $res_dir                \
    --chrom $chroms            \
    -p $n                      \
    --cellTAG CB               \
    --UMItag UB                \
    --minCOUNT $min_count       \
    --minMAF $min_maf          \
    --minLEN $min_len          \
    --minMAPQ $min_mapq        \
    --exclFLAG 772             \
    --inclFLAG 0               \
    --gzip                    \
    --genotype                \
> $res_dir/run.out 2> $res_dir/run.err
sleep 5

# run mode 2b + mode 1a
res_dir=$out_dir/2b-1a_${i}_$n
if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
echo "[I::$prog] mode 2b + 1a (repeat=$i; ncores=$n) to '$res_dir' ..."

mode2b_dir=$res_dir/2b
if [ ! -d "$mode2b_dir" ]; then mkdir -p $mode2b_dir; fi
script=$res_dir/2b-1a_${i}_${n}.sh
echo "#!/bin/bash"                         > $script
echo "set -eu"                            >> $script
echo "set -o pipefail"                    >> $script
echo "# run mode 2b"                      >> $script
echo "/usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \\"  >> $script
echo "  $BIN_DIR/cellsnp-lite        \\"  >> $script
echo "    -s $bam                    \\"  >> $script
echo "    -O $mode2b_dir             \\"  >> $script
echo "    --chrom $chroms            \\"  >> $script
echo "    -p $n                      \\"  >> $script
echo "    --cellTAG None             \\"  >> $script
echo "    --UMItag None              \\"  >> $script
echo "    --minCOUNT $min_count      \\"  >> $script
echo "    --minMAF $min_maf          \\"  >> $script
echo "    --minLEN $min_len          \\"  >> $script
echo "    --minMAPQ $min_mapq        \\"  >> $script
echo "    --exclFLAG 772             \\"  >> $script
echo "    --inclFLAG 0               \\"  >> $script
echo "    --gzip                     \\"  >> $script
echo "    --genotype                 \\"  >> $script
echo "> $res_dir/2b.out 2> $res_dir/2b.err"  >> $script
echo ""                                 >> $script
echo "# run mode 1a"                    >> $script
echo "/usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \\"  >> $script
echo "  $BIN_DIR/cellsnp-lite        \\"  >> $script
echo "    -s $bam                    \\"  >> $script
echo "    -b $barcode                \\"  >> $script
echo "    -O $res_dir                \\"  >> $script
echo "    -R $mode2b_dir/cellSNP.base.vcf.gz  \\"  >> $script
echo "    -p $n                      \\"  >> $script
echo "    --cellTAG CB               \\"  >> $script
echo "    --UMItag UB                \\"  >> $script
echo "    --minCOUNT $min_count      \\"  >> $script
echo "    --minMAF $min_maf          \\"  >> $script
echo "    --minLEN $min_len          \\"  >> $script
echo "    --minMAPQ $min_mapq        \\"  >> $script
echo "    --exclFLAG 772             \\"  >> $script
echo "    --inclFLAG 0               \\"  >> $script
echo "    --gzip                     \\"  >> $script
echo "    --genotype"                \\   >> $script
echo "> $res_dir/1a.out 2> $res_dir/1a.err"  >> $script
echo ""                                 >> $script

chmod u+x $script
/usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
  $script     \
> $res_dir/run.out 2> $res_dir/run.err
sleep 5

# run common_SNP + mode 1a
res_dir=$out_dir/cSNP-1a_${i}_$n
if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
echo "[I::$prog] common-SNP + mode 1a (repeat=$i; ncores=$n) to '$res_dir' ..."
/usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
  $BIN_DIR/cellsnp-lite         \
    -s $bam                     \
    -b $barcode                \
    -R $snp                    \
    -O $res_dir                \
    -p $n                      \
    --cellTAG CB               \
    --UMItag UB                 \
    --minCOUNT $min_count        \
    --minMAF $min_maf         \
    --minLEN $min_len          \
    --minMAPQ $min_mapq        \
    --exclFLAG 772             \
    --inclFLAG 0               \
    --gzip                    \
    --genotype                \
> $res_dir/run.out 2> $res_dir/run.err

echo "[I::$prog] Done!"

