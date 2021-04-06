#!/bin/bash

set -eux

./plot_efficiency.r \
  -i 1a_souporcell.efficiency.tsv \
  -f 1a_souporcell.efficiency.tiff \
  --time wall \
  --title "Mode 1a"  \
  --width 3.5      \
  --height 4     \
  --dpi 300  \
  --xlegend 0.89  \
  --ylegend 0.13

./plot_efficiency.r \
  -i 1b_cardelino.efficiency.tsv \
  -f 1b_cardelino.efficiency.tiff \
  --time wall \
  --title "Mode 1b"  \
  --width 3.5      \
  --height 4     \
  --dpi 300  \
  --xlegend 0.89  \
  --ylegend 0.83

./plot_efficiency.r \
  -i 2b_souporcell.efficiency.tsv \
  -f 2b_souporcell.efficiency.tiff \
  --time wall \
  --title "Mode 2b"  \
  --width 3.5      \
  --height 4     \
  --dpi 300  \
  --xlegend 0.89  \
  --ylegend 0.13

# plot_accuracy.r <input> <output> <width> <height>
./plot_accuracy.r \
  ../../supplementary/table_s5_1a_souporcell_correlation.tsv \
  1a_souporcell.correlation.tiff  \
  4 \
  3.1

# 2b_souporcell.3tools.PRC.tiff was initially named 
python ../../../run/2b_souporcell/stat_accuracy_PRCurve.py \
  --name1 cellsnp-lite \
  --infile1 cellsnp-lite.array.freebayes.precision.recall.tsv \
  --name2 freebayes \
  --infile2 freebayes.array.cellsnp-lite.precision.recall.tsv \
  --outfig 2b_souporcell.3tools.PRC.tiff \
  --width 4.3   \
  --height 3.1

echo Done!

