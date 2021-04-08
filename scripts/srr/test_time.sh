#!/bin/bash
#Aim: to test if /usr/bin/time could estimate correctly peak memory
#     (Max RSS) for cellSNP which uses python multiprocessing.

set -eux

# the $bam, $barcode, and $snp are all from the souporcell dataset described
# in the section 2.3 in supplementary file.
bam=~/data/cellsnp-bm/bm_sc/cr_hg19/SAMEA4810598_euts_1/outs/possorted_genome_bam.bam
barcode=~/data/cellsnp-bm/bm_sc/cr_hg19/SAMEA4810598_euts_1/outs/filtered_feature_bc_matrix/barcodes.tsv
snp=~/data/cellsnp-bm/bm1_demux/genome1K.phase3.SNP_AF5e2.chr1toX.hg19.noindel.nobiallele.nodup.vcf.gz
dir=.

# run cellSNP v0.3.2 with 200G assigned memory
# peak memory (Max RSS): ~4.7G by /usr/bin/time
qsub -q cgsd -N test -l nodes=1:ppn=16,mem=200gb,walltime=100:00:00 \
  -o $dir/time_200G.out -e $dir/time_200G.err -- \
  /usr/bin/time --verbose \
    ~/.anaconda3/envs/CSP/bin/cellSNP \
      -s $bam \
      -b $barcode \
      -R $snp   \
      -O $dir/time_200G \
      -p 16 \
      --cellTAG CB \
      --UMItag UB \
      --minMAF 0 \
      --minCOUNT 1 \
      --minLEN 0  \
      --minMAPQ 20 \
      --maxFLAG 4096

# run cellSNP v0.3.2 with 200G assigned memory
# peak memory: ~60.3G by memusg 
# (https://github.com/hxj5/csp-benchmark/blob/master/run/utils/memusg)
qsub -q cgsd -N test -l nodes=1:ppn=16,mem=200gb,walltime=100:00:00 \
  -o $dir/memusg_200G.out -e $dir/memusg_200G.err -- \
  python $dir/memusg -t -H \
    ~/.anaconda3/envs/CSP/bin/cellSNP \
      -s $bam \
      -b $barcode \
      -R $snp   \
      -O $dir/memusg_200G \
      -p 16 \
      --cellTAG CB \
      --UMItag UB \
      --minMAF 0 \
      --minCOUNT 1 \
      --minLEN 0  \
      --minMAPQ 20 \
      --maxFLAG 4096

# run cellSNP v0.3.2 with 20G assigned memory
# this would cause error:
#   =>> PBS: job killed: mem 59756048kb exceeded limit 20971520kb
qsub -q cgsd -N test -l nodes=1:ppn=16,mem=20gb,walltime=100:00:00 \
  -o $dir/time_20G.out -e $dir/time_20G.err -- \
  /usr/bin/time --verbose \
    ~/.anaconda3/envs/CSP/bin/cellSNP \
      -s $bam \
      -b $barcode \
      -R $snp   \
      -O $dir/time_20G \
      -p 16 \
      --cellTAG CB \
      --UMItag UB \
      --minMAF 0 \
      --minCOUNT 1 \
      --minLEN 0  \
      --minMAPQ 20 \
      --maxFLAG 4096

