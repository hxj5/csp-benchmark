
Softwares
=========

Benchmarking requires all dependent softwares to be installed beforehand. 

1. Install most softwares via conda
-----------------------------------

For most softwares, a conda yaml file `cellsnp-lite.benchmark.conda.yml`_ is 
provided, which is aimed to make the installation easier by simply running,

.. code-block:: bash

  conda env create -f cellsnp-lite.benchmark.conda.yml

Then the softwares would be installed to a new conda env named ``CSP``. The global
variable ``BIN_DIR`` in `config.sh`_ should be set to absolute path to the 
``bin`` dir of CSP env (something like ~/.anaconda3/envs/CSP/bin).

2. Install remaining softwares manually
---------------------------------------

Vartrix
~~~~~~~

Besides, vartrix should be downloaded with

.. code-block:: bash

  wget https://github.com/10XGenomics/vartrix/releases/download/v1.1.16/vartrix_linux 

and then unzipped and copied to ``BIN_DIR``.

R packages
~~~~~~~~~~

Lastly, there are several R packages needed to be installed manually in ``CSP`` env: 
``argparse``, ``tibble``, ``stringr``, ``ggplot2``, ``dplyr``,
``tidyr``, ``ggrepel`` by

.. code-block:: bash

   conda activate CSP
   R
   # then install.packages(<package>) in R

.. _cellsnp-lite.benchmark.conda.yml: https://github.com/hxj5/csp-benchmark/blob/master/bin/cellsnp-lite.benchmark.conda.yml
.. _config.sh: https://github.com/hxj5/csp-benchmark/blob/master/config.sh

