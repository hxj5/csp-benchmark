#!/bin/bash
#Aim: to benchmark mode1b (well-based dataset with given SNPs)
#  on cardelino dataset using 3 tools: bcftools (-R/-T), cellSNP, 
#  cellsnp-lite (-R/-T)
#Dependency: /usr/bin/time

set -e
set -o pipefail

if [ $# -lt 2 ]; then
  echo "" >&2
  echo "This script is aimed to benchmark mode1b (well-based dataset with given" >&2
  echo "SNPs) on cardelino dataset using 3 tools: bcftools (-R/-T), cellSNP and" >&2
  echo "cellsnp-lite (-R/-T)." >&2
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

run=1b_cardelino
util_dir=$work_dir/../utils
out_dir=$RES_DIR/$run/run
if [ ! -d "$out_dir" ]; then mkdir -p $out_dir; fi
echo "[I::$prog] Benchmark $run and output to '$out_dir' ..."

bam_lst=$DATA_DIR/cardelino/carde.bam.lst
sample_lst=$DATA_DIR/cardelino/carde.sample.lst
snp=$DATA_DIR/snp/genome1K.phase3.SNP_AF5e2.chr1toX.hg19.snp.uniq.vcf.gz
fasta=$DATA_DIR/fasta/cellranger.hg19.3.0.0.fa
cell_tag=None
umi_tag=None
min_mapq=20
min_count=1
min_maf=0
min_len=0

set -x

# run bcftools (-R/-T)
for opt in -R -T; do
  res_dir=$out_dir/bcftools${opt}_${i}_$n
  if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
  echo "[I::$prog] bcftools$opt (repeat=$i; ncores=$n) to '$res_dir' ..."

  script=$res_dir/bcftools${opt}_${i}_${n}.sh
  echo "#!/bin/bash"                       > $script
  echo "set -eu"                          >> $script
  echo "set -o pipefail"                  >> $script
  echo "$BIN_DIR/bcftools mpileup   \\"   >> $script
  echo "  -b $bam_lst               \\"   >> $script
  echo "  -d 100000                 \\"   >> $script
  echo "  -f $fasta                 \\"   >> $script
  echo "  -q $min_mapq              \\"   >> $script
  echo "  -Q 0                      \\"   >> $script
  echo "  --excl-flags 1796         \\"   >> $script
  echo "  --incl-flags 0            \\"   >> $script
  echo "  $opt $snp                 \\"   >> $script
  echo "  -a AD,DP                  \\"   >> $script
  echo "  -I                        \\"   >> $script
  echo "  --threads $n              \\"   >> $script
  echo "  -Ou |                     \\"   >> $script
  echo "$BIN_DIR/bcftools view      \\"   >> $script
  echo "  -i 'INFO/DP > 0'          \\"   >> $script
  echo "  -V indels                 \\"   >> $script
  echo "  --threads $n              \\"   >> $script
  echo "  -Oz                       \\"   >> $script
  echo "  -o $res_dir/bcftools.vcf.gz"    >> $script
  echo ""                                 >> $script

  chmod u+x $script
  /usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
    $script  \
  > $res_dir/run.out 2> $res_dir/run.err
  sleep 5
done

# run cellSNP
res_dir=$out_dir/cellSNP_${i}_$n
if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
echo "[I::$prog] cellSNP (repeat=$i; ncores=$n) to '$res_dir' ..."
samples=`cat $sample_lst | tr '\n' ',' | sed 's/,$//'`
/usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
  $BIN_DIR/cellSNP             \
    -S $bam_lst                \
    -I $samples                \
    -O $res_dir                \
    -R $snp                    \
    -p $n                      \
    --cellTAG $cell_tag       \
    --UMItag $umi_tag          \
    --minCOUNT $min_count        \
    --minMAF $min_maf         \
    --minLEN $min_len          \
    --minMAPQ $min_mapq        \
    --maxFLAG 255            \
> $res_dir/run.out 2> $res_dir/run.err
sleep 5

# run cellsnp-lite (-R/-T)
for opt in -R -T; do
  res_dir=$out_dir/cellsnp-lite${opt}_${i}_$n
  if [ ! -d "$res_dir" ]; then mkdir -p $res_dir; fi
  echo "[I::$prog] cellsnp-lite$opt (repeat=$i; ncores=$n) to '$res_dir' ..."
  /usr/bin/time -v $BIN_DIR/python $util_dir/memusg -t -H \
    $BIN_DIR/cellsnp-lite         \
      -S $bam_lst                 \
      -i $sample_lst             \
      -O $res_dir                \
      $opt $snp                  \
      -p $n                      \
      --cellTAG $cell_tag       \
      --UMItag $umi_tag          \
      --minCOUNT $min_count        \
      --minMAF $min_maf         \
      --minLEN $min_len          \
      --minMAPQ $min_mapq        \
      --exclFLAG 1796            \
      --inclFLAG 0               \
      --gzip                    \
      --genotype                \
  > $res_dir/run.out 2> $res_dir/run.err
  sleep 5
done

echo "[I::$prog] Done!"

