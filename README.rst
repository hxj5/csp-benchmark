
csp-benchmark
=============

It's the repo for benchmarking of `cellsnp-lite`_. Cellsnp-lite is implemented 
in C and performs per cell genotyping, supporting both with (mode 1) and 
without (mode 2) given SNPs. In the latter case, heterozygous SNPs will be 
detected automatically. Cellsnp-lite is applicable for both droplet-based 
(e.g., 10x Genomics data) and well-based platforms (e.g., SMART-seq2 data). 
See Table 1 for summary of these four options, and example alternatives in 
each mode.

.. csv-table:: Table 1
   :header: "Mode", "SNPs", "Bam files", "Platform", "Alternative"
   :widths: 20, 20, 20, 20, 40

   "Mode 1a", "Given", "Pooled one", "Droplet", "VarTrix"
   "Mode 1b", "Given", "Each per cell", "SMART-seq", "BCFtools mpileup"
   "Mode 2a", "To detect", "Pooled one", "Droplet", "N.A."
   "Mode 2b", "To detect", "Each per cell", "SMART-seq", "Freebayes"

How to use
----------

This repo includes six runs in dir `run`_, each is for a specific benchmarking
task. A wrapper script `benchmark.sh`_ is provided to make it easier to run 
single task.

To use the repo, please first clone it to your local machine,

.. code-block:: bash

  git clone https://github.com/hxj5/csp-benchmark.git

1. Preparation
~~~~~~~~~~~~~~

Before running any benchmarking task, all dependent softwares and datasets
should have been installed or well prepared. To achieve this, please firstly
check and modify `config.sh`_ and then follow the instructions in 
`doc/software.rst`_ and `doc/dataset.rst`_.

2. Run benchmark task
~~~~~~~~~~~~~~~~~~~~~

Once softwares and datasets have been well prepared, you could run single 
benchmark task with the wrapper script `benchmark.sh`_,

.. code-block:: html

  This script is a wrapper for benchmarking cellsnp-lite
  
  Usage: ./benchmark.sh <mode> <action>
  
  <mode> is the target mode for benchmarking, could be one of:
    1a-demuxlet      Demuxlet dataset with given SNPs
    1a-souporcell    Souporcell dataset with given SNPs
    1b-cardelino     Cardelino dataset with given SNPs
    2a-souporcell    Souporcell dataset without given SNPs
    2b-cardelino     Cardelino dataset without given SNPs
    2b-souporcell    Souporcell dataset (bulk mode) without given SNPs
  <action> could be one of:
    run        Execute the run.sh to get time & memory usage
    analysis   Execute the stat_efficiency.sh and stat_accuracy.sh
  
  Note:
    Please make sure all software dependencies and datasets have
    been installed and check config.sh before using this script
   
Benchmark Results
-----------------

The benchmark results were initially described in the `preprint`_ and the 
corresponding version (an old version, v1) of benchmarking scripts are in 
`scripts/benchmark_v1`_.

.. _cellsnp-lite: https://github.com/single-cell-genetics/cellsnp-lite
.. _run: https://github.com/hxj5/csp-benchmark/tree/master/run
.. _benchmark.sh: https://github.com/hxj5/csp-benchmark/blob/master/benchmark.sh
.. _config.sh: https://github.com/hxj5/csp-benchmark/blob/master/config.sh
.. _doc/software.rst: https://github.com/hxj5/csp-benchmark/blob/master/doc/software.rst
.. _doc/dataset.rst: https://github.com/hxj5/csp-benchmark/blob/master/doc/dataset.rst
.. _preprint: https://www.biorxiv.org/content/10.1101/2020.12.31.424913v1.full
.. _scripts/benchmark_v1: https://github.com/hxj5/csp-benchmark/tree/master/scripts/benchmark_v1

