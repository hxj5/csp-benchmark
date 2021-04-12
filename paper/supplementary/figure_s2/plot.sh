#!/bin/bash

set -eux

python ../../../run/2b_souporcell/stat_accuracy_PRCurve.py \
  --name1 cellsnp-lite \
  --infile1 cellsnp-lite.array.precision.recall.tsv \
  --outfig cellsnp-lite.array.precision.recall.tiff \
  --color red

python ../../../run/2b_souporcell/stat_accuracy_PRCurve.py \
  --name1 freebayes \
  --infile1 freebayes.array.precision.recall.tsv \
  --outfig freebayes.array.precision.recall.tiff \
  --color blue

python ../../../run/2b_souporcell/stat_accuracy_PRCurve.py \
  --name1 cellsnp-lite \
  --infile1 cellsnp-lite.array.freebayes.precision.recall.tsv \
  --name2 freebayes \
  --infile2 freebayes.array.cellsnp-lite.precision.recall.tsv \
  --outfig array.cellsnp-lite.freebayes.precision.recall.tiff

echo Done!

