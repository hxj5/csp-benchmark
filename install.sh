#!/bin/bash
#Aim: to install all tools & datasets needed by benchmarking
#Example:

set -eu
set -o pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <mode>" >&2
  echo "<mode> is the target mode for benchmarking, could be one of:" >&2
  echo "  all        All modes (the default)" >&2
  echo "  1a     Droplet-based dataset with given SNPs" >&2
  echo "  1b     Well-based dataset with given SNPs" >&2
  echo "  2a     Droplet-based dataset without given SNPs" >&2
  echo "  2b     Well-based dataset without given SNPs" >&2
  exit 1
fi

work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`
mode=$1

echo "Install dataset '$dataset' ..."
case $dataset in
  cardelino) install_cardelino ;;
  demuxlet) install_demuxlet ;;
  fasta) install_fasta ;;
  snp) install_snp ;;
  souporcell) install_souporcell ;;
  *) echo "[E::$prog] invalid dataset name '$dataset'" >&2 ;;
esac

