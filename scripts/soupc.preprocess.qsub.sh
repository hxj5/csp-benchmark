#!/bin/bash
#PBS -N soupc_preprocess
#PBS -q cgsd
#PBS -l nodes=1:ppn=31
#PBS -l mem=210gb
#PBS -l walltime=200:00:00
#Aim: to run cellranger count pipeline on 64 fastq files of ENA sample 
#     SAMEA4810598 euts_1, which is part of souporcell dataset.

set -eux

work_dir=~/data/cellsnp-bm/bm_sc
fastq_dir=$work_dir/fq
out_dir=$work_dir/cr_hg19
sample_lst=$work_dir/soupc.samples.lst    # 32 samples, one sample name per line

# Step-1, download all 64 fastq files of 32 samples from ENA to $fastq_dir
# Link: https://www.ebi.ac.uk/ena/browser/view/SAMEA4810598

# Step-2, rename fastq files to meet cell-ranger's requirements.
for fq in `ls $fastq_dir/*.fastq.gz`; do
    fn=`basename $fq`
    sample=${fn%%_*}
    tmp_reads=${fn##*_}
    reads=${tmp_reads%%.fastq.gz}
    new_fq=$fq_dir/${sample}_S1_L001_R${reads}_001.fastq.gz
    mv $fq $new_fq
done

# Step-3, run cellranger-count pipeline
samples=`cat $sample_lst | tr '\n' ',' | sed 's/,$//'`
cd $out_dir
~/tools/cellranger-4.0.0/cellranger count \
  --id=SAMEA4810598_euts_1    \
  --transcriptome=~/data/cellranger/refdata-cellranger-hg19-3.0.0  \
  --fastqs=$fastq_dir         \
  --chemistry=SC3Pv2          \
  --sample=$samples           \
  --localcores=30             \
  --localmem=200

