#!/bin/bash 
#Aim: to compare the accuracy of different apps

set -e
set -o pipefail

# print usage message of this script. e.g. usage test.sh
function usage() {
    echo
    echo "This script is aimed to compare the accuracy of different apps"
    echo
    echo "Usage: $1 [options]"
    echo
    echo "Options:"
    echo "  --name1 STR        Name of app1"
    echo "  --variant1 FILE    Variant file of app1: vcf or region file"
    echo "  --ref1 FILE        Ref mtx of app1"
    echo "  --alt1 FILE        Alt mtx of app1"
    echo "  --name2 STR        Name of app2"
    echo "  --variant2 FILE    Variant file of app2: vcf or region file"
    echo "  --ref2 FILE        Ref mtx of app2"
    echo "  --alt2 FILE        Alt mtx of app2"
    echo "  -O, --out-dir DIR  Directory of outputing files."
    echo "  -h, --help         This message."
    echo
    echo "Notes:"
    echo "  Region file's first two columns should be <chrom> <pos> and"
    echo "  pos is 1-based."
    echo
}

# parse command line args
if [ $# -lt 1 ]; then
    usage $0
    exit 1
fi

work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`
ARGS=`getopt -o O:h --long name1:,variant1:,ref1:,alt1:,name2:,variant2:,ref2:,alt2:,out-dir:,help -n "" -- "$@"`
if [ $? -ne 0 ]; then
    echo "[E::$prog] failed to parse command line args. Terminating..." >&2
    exit 1
fi
eval set -- "$ARGS"
while true; do
    case "$1" in
        --name1) name1=$2; shift 2;;
        --variant1) var1=$2; shift 2;;
        --ref1) ref1=$2; shift 2;;
        --alt1) alt1=$2; shift 2;;
        --name2) name2=$2; shift 2;;
        --variant2) var2=$2; shift 2;;
        --ref2) ref2=$2; shift 2;;
        --alt2) alt2=$2; shift 2;;
        -O|--out-dir) out_dir=$2; shift 2;;
        -h|--help) print_usage $script_name; shift; exit 0;;
        --) shift; break;;
        *) echo "[E::$prog] invalid cmdline parameter '$1'!" >&2; exit 1;;
    esac
done

echo "[I::$prog] Comparing accuracy of '$name1' and '$name2' to '$out_dir' ..."

if [ -z "$BIN_DIR" ]; then
    source $work_dir/../../config.sh > /dev/null
fi

set -xu

# merge variants
merged_var=$out_dir/merged.variants.tsv
$BIN_DIR/Rscript $work_dir/snp_merge.r \
  -1 $var1 -2 $var2 -o $merged_var
nvar=`cat $merged_var | wc -l`

# match variant index
idx1=$out_dir/${name1}.match.idx
$BIN_DIR/Rscript $work_dir/snp_idx_match.r \
  -1 $var1 -2 $merged_var -o $idx1

idx2=$out_dir/${name2}.match.idx
$BIN_DIR/Rscript $work_dir/snp_idx_match.r \
  -1 $var2 -2 $merged_var -o $idx2

# update mtx snp index
new_ref1=$out_dir/${name1}.update.ref.mtx
$BIN_DIR/Rscript $work_dir/mtx_update_snp.r \
  --mtx $ref1 --index $idx1 -N $nvar -o $new_ref1 

new_alt1=$out_dir/${name1}.update.alt.mtx
$BIN_DIR/Rscript $work_dir/mtx_update_snp.r \
  --mtx $alt1 --index $idx1 -N $nvar -o $new_alt1 

new_ref2=$out_dir/${name2}.update.ref.mtx
$BIN_DIR/Rscript $work_dir/mtx_update_snp.r \
  --mtx $ref2 --index $idx2 -N $nvar -o $new_ref2

new_alt2=$out_dir/${name2}.update.alt.mtx
$BIN_DIR/Rscript $work_dir/mtx_update_snp.r \
  --mtx $alt2 --index $idx2 -N $nvar -o $new_alt2

# plot accuracy
accu_dir=$out_dir/accu
if [ ! -d "$accu_dir" ]; then mkdir -p $accu_dir; fi
$BIN_DIR/Rscript $work_dir/plot_accuracy.r \
  --ref1 $new_ref1 --alt1 $new_alt1 --name1 $name1 \
  --ref2 $new_ref2 --alt2 $new_alt2 --name2 $name2 \
  -O $accu_dir

