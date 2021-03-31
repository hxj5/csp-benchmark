#!/bin/bash
#Aim: to benchmark certain mode which is one of:
#  1a-demuxlet, 1a-souporcell, 1b-cardelino
#  2a-souporcell, 2b-cardelino, 2b-souporcell
#Example

set -e
set -o pipefail

if [ $# -lt 2 ]; then
  echo "" >&2
  echo "This script is a wrapper for benchmarking cellsnp-lite" >&2
  echo "" >&2
  echo "Usage: $0 <mode> <action>" >&2
  echo "" >&2
  echo "<mode> is the target mode for benchmarking, could be one of:" >&2
  echo "  1a-demuxlet      Demuxlet dataset with given SNPs" >&2
  echo "  1a-souporcell    Souporcell dataset with given SNPs" >&2
  echo "  1b-cardelino     Cardelino dataset with given SNPs" >&2
  echo "  2a-souporcell    Souporcell dataset without given SNPs" >&2
  echo "  2b-cardelino     Cardelino dataset without given SNPs" >&2
  echo "  2b-souporcell    Souporcell dataset (bulk mode) without given SNPs" >&2
  echo "<action> could be one of:" >&2
  echo "  run        Execute the run.sh to get time & memory usage" >&2
  echo "  analysis   Execute the stat_efficiency.sh and stat_accuracy.sh" >&2
  echo "" >&2
  echo "Note:" >&2
  echo "  Please make sure all software dependencies and datasets have" >&2
  echo "  been installed and check config.sh before using this script" >&2
  echo "" >&2
  exit 1
fi

set -x

mode=$1
action=$2
work_dir=`cd $(dirname $0) && pwd`
prog=`basename $0`

if [ -z "$HAS_PBS" ] || [ -z "$PBS_QUEUE" ] || [ -z "$NREP" ] || [ -z "$RES_DIR" ]; then
  source $work_dir/config.sh 
fi

set -u

run=${mode/-/_}

if [ "$action" == "run" ]; then
  echo "[I::$prog] Run '$mode' ..."
  case $mode in
    1a-demuxlet) rep=`seq 1 $NREP`; ncores="8 16 32";;
    1a-souporcell) rep=`seq 1 $NREP`; ncores="8 16 32";;
    1b-cardelino) rep=`seq 1 $NREP`; ncores="1 2 4 8";;
    2a-souporcell) rep="1"; ncores="16";;
    2b-cardelino) rep=`seq 1 $NREP`; ncores="1 2 4 8";;
    2b-souporcell) rep=`seq 1 $NREP`; ncores="8 16 32";;
    *) echo "[E::$prog] error <mode> '$mode'" >&2; exit 1;;
  esac
  if [ ! -d "$RES_DIR/$run/run" ]; then mkdir -p $RES_DIR/$run/run; fi
  for i in $rep; do
    for n in $ncores; do
      out=$RES_DIR/$run/run/${mode}_${i}_${n}.out
      err=$RES_DIR/$run/run/${mode}_${i}_${n}.err
      if [ $HAS_PBS -eq 1 ]; then
        qsub -q $PBS_QUEUE -N ${mode}-run \
          -l nodes=1:ppn=$n,mem=200gb,walltime=150:00:00 \
          -o $out -e $err -- $work_dir/run/$run/run.sh
      else
         $work_dir/run/$run/run.sh > $out 2> $err &
      fi
    done
  done
elif [ "$action" == "analysis" ]; then
  if [ ! -d "$RES_DIR/$run/efficiency" ]; then mkdir -p $RES_DIR/$run/efficiency; fi
  if [ ! -d "$RES_DIR/$run/accuracy" ]; then mkdir -p $RES_DIR/$run/accuracy; fi
  if [ $HAS_PBS -eq 1 ]; then
    qsub -q $PBS_QUEUE -N ${mode}-efficiency \
      -l nodes=1:ppn=5,mem=20gb,walltime=1:00:00 \
      -o $RES_DIR/$run/efficiency/${mode}_efficiency.out \
      -e $RES_DIR/$run/efficiency/${mode}_efficiency.err \
      -- $work_dir/run/$run/stat_efficiency.sh
    qsub -q $PBS_QUEUE -N ${mode}-accuracy \
      -l nodes=1:ppn=5,mem=80gb,walltime=100:00:00 \
      -o $RES_DIR/$run/accuracy/${mode}_accuracy.out \
      -e $RES_DIR/$run/accuracy/${mode}_accuracy.err \
      -- $work_dir/run/$run/stat_accuracy.sh
  else
    $work_dir/run/$run/stat_efficiency.sh \
      > $RES_DIR/$run/efficiency/${mode}_efficiency.out \
      2> $RES_DIR/$run/efficiency/${mode}_efficiency.err &
    $work_dir/run/$run/stat_accuracy.sh \
      > $RES_DIR/$run/accuracy/${mode}_accuracy.out \
      2> $RES_DIR/$run/accuracy/${mode}_accuracy.err &
  fi
else
  echo "[E::$prog] error <action> '$action'" >&2
  exit 1
fi

