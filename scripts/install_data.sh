#!/bin/bash
#Aim: to install (download and pre-process if needed) all datasets used for benchmarking
#Dependency:
#

set -e
set -o pipefail

function install_cardelino() {

  # it's best if we could download the whole dir with one try
  if [ ! -f "$dat_dir/..." ]; then wget ... -O $dat_dir/...; fi;
}

function install_demuxlet() {

}

function install_fasta() {
  wget http://cf.10xgenomics.com/supp/cell-exp/refdata-cellranger-hg19-3.0.0.tar.gz
}

function install_snp() {

}

function install_souporcell() {

}

if [ $# -lt 1 ]; then
  echo "Usage: $0 <dataset>" >&2
  echo "dataset could be one of cardelino|demuxlet|fasta|snp|souporcell" >&2
  exit 1
fi

work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`
dataset=$1

if [ -z "$DATA_DIR" ]; then
  source $work_dir/../config.sh > /dev/null
fi

set -u

dat_dir=$DATA_DIR/$dataset
echo "[I::$prog] Install dataset '$dataset' to '$dat_dir' ..."
case $dataset in
  cardelino) install_cardelino ;;
  demuxlet) install_demuxlet ;;
  fasta) install_fasta ;;
  snp) install_snp ;;
  souporcell) install_souporcell ;;
  *) echo "[E::$prog] invalid dataset name '$dataset'" >&2 ;;
esac

