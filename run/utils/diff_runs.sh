#!/bin/bash 
#Aim: to compare results among different runs of certain tool
#Example: ./diff_runs.sh <tool> <dir>
#  <tool> name of tool
#  <dir> should contain several subdirs whose names start with <tool>

function diff_dir() {
  local lst=`ls "$1" | tr ' ' '\n' | grep -v '\.sh$' | grep -v '^run\.' | \
         grep -v '\.log$' | grep -v '\.out$' | grep -v '\.err$' | \
         grep -v 'cellSNP\.cells\.vcf\.gz$'`
  for fn in $lst; do
    if [ ! -f "$2/$fn" ]; then return 1; fi
    set +e
    if [ ${fn##*.} == gz ]; then
      diff <(zcat $1/$fn | grep -v '^#') \
           <(zcat $2/$fn | grep -v '^#') \
           &> /dev/null
    else
      diff <(cat $1/$fn | grep -v '^#') \
           <(cat $2/$fn | grep -v '^#') \
           &> /dev/null
    fi
    if [ $? -ne 0 ]; then return 1; fi
    set -e 
  done
  return 0
}

set -eu
set -o pipefail

if [ $# -lt 2 ]; then
  echo "" >&2
  echo "This script is aimed to compare results among different runs of certain tool." >&2
  echo "" >&2
  echo "Usage: $0 <tool> <dir>" >&2
  echo "" >&2
  echo "<tool> name of tool, eg., cellsnp-lite." >&2
  echo "<dir> should contain several subdirs whose names start with <tool>." >&2
  echo "" >&2
  exit 1
fi
tool=$1
dir0=$2
prog=`basename $0`

echo "[I::$prog] compare results among different runs of $tool in '$dir0' ..."

idx=1
dir1=
for dir2 in `ls $dir0 | tr ' ' '\n' | grep ^$tool`; do
  dir2=$dir0/$dir2
  if [ ! -d "$dir2" ]; then continue; fi
  if [ $idx -gt 1 ]; then
    diff_dir "$dir1" "$dir2"
    if [ $? -ne 0 ]; then
      echo "[E::$prog] '$dir1' and '$dir2' have different outputs!" >&2
      exit 1
    else
      echo "[I::$prog] '$dir1' and '$dir2' have the same output!"
    fi
  fi
  dir1=$dir2
  let idx=idx+1
done

