#!/bin/bash
#PBS -N cardelino_preprocess
#PBS -q cgsd
#PBS -l nodes=1:ppn=8
#PBS -l mem=60gb
#PBS -l walltime=300:00:00
#Aim: to align 10 fastq files of joxm sample to hg19 with STAR

fastq_dir=~/data/cellsnp-bm/bm3_fb
fasta=~/data/cellranger/refdata-cellranger-hg19-3.0.0/fasta/genome.fa
genome_dir=~/data/cellsnp-bm/bm3_fb/star
aln_dir=~/data/cellsnp-bm/bm3_fb/aln
mkdir -p $aln_dir &> /dev/null
out_dir=~/data/cellsnp-bm/bm3_fb/sort
mkdir $out_dir &> /dev/null

set -eux

# Step-1: download the 10 fastq files to $fastq_dir
# Link: https://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-7167/samples/?full=true&s_sortby=col_42&s_sortorder=ascending&s_page=14&s_pagesize=100

# Step-2: index genome with STAR
~/.anaconda3/envs/CSP/bin/STAR \
  --runThreadN 4   \
  --runMode genomeGenerate  \
  --genomeDir $genome_dir   \
  --genomeFastaFiles $fasta

# Step-3: align fastq to hg19
smp_list=`cd ${fastq_dir}; ls *.fastq.gz | tr ' ' '\n' | sed 's/_.*//' | sort -u`
for name in $smp_list; do
  fq1=$fastq_dir/${name}_1.fastq.gz
  fq2=$fastq_dir/${name}_2.fastq.gz
  ~/.anaconda3/envs/CSP/bin/STAR \
    --runThreadN 8    \
    --genomeDir $genome_dir  \
    --readFilesCommand zcat  \
    --readFilesIn $fq1 $fq2  \
    --outFileNamePrefix $aln_dir/${name}. \
  > $aln_dir/${name}.out     \
  2> $aln_dir/${name}.err
done

# Step-4: convert sam to bam and then sort & index
for f in `ls $aln_dir/*.sam`; do
  sample=`basename ${f%%.*}`
  tmp_bam=$out_dir/${sample}.bam
  bam=$out_dir/${sample}.sort.bam
  samtools view -h -b $f > $tmp_bam
  samtools sort -O BAM $tmp_bam > $bam
  rm $tmp_bam
  samtools index $bam
done

