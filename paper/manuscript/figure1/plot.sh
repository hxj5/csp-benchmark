#!/bin/bash

set -eux

./plot_efficiency.r \
  -i 1a_souporcell.efficiency.tsv \
  -f 1a_souporcell.efficiency.tiff \
  --time wall \
  --title "Mode 1a"  \
  --width 3.5      \
  --height 4.5     \
  --dpi 300  \
  --xlegend 0.9  \
  --ylegend 0.12

./plot_efficiency.r \
  -i 1b_cardelino.efficiency.tsv \
  -f 1b_cardelino.efficiency.tiff \
  --time wall \
  --title "Mode 1b"  \
  --width 3.5      \
  --height 4.5     \
  --dpi 300  \
  --xlegend 0.9  \
  --ylegend 0.85

./plot_efficiency.r \
  -i 2b_souporcell.efficiency.tsv \
  -f 2b_souporcell.efficiency.tiff \
  --time wall \
  --title "Mode 2b"  \
  --width 3.5      \
  --height 4.5     \
  --dpi 300  \
  --xlegend 0.9  \
  --ylegend 0.12

./plot_accuracy.r \
  ../../supplementary/table_s5_1a_souporcell_correlation.tsv \
  1a_souporcell.correlation.tiff

# 2b_souporcell.3tools.PRC.tiff was initially named 
# 2b_souporcell.array.cellsnp-lite.freebayes.precision.recall.tiff
# which was plotted in run 2b_souporcell by stat_accuracy.sh

echo Done!

