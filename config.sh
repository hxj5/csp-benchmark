#!/bin/bash
#Aim: to set global variables
#Note:
#  1. change variables on your demands
#  2. this script would be sourced by other scripts to import global variables

cfg_prog=`basename $BASH_SOURCE`   # $BASH_SOURCE is more suitable than $0 when sourced
echo "[I::$cfg_prog] Set Global Variables ..."

# absolute path to the root dir of this project
PROJECT_DIR=`cd $(dirname $BASH_SOURCE) && pwd`

###### Set Global Variables
# name of conda env used for benchmarking
ENV_NAME=CSP

# absolute path to `bin` dir containing the binaries
# used for benchmarking
BIN_DIR=~/.anaconda3/envs/${ENV_NAME}/bin

# absolute path to the root dir that containing subdirs
# of all datasets
DATA_DIR=$PROJECT_DIR/data

# absolute path to the root dir containing result dirs
# of all benchmarking experiments
RES_DIR=$PROJECT_DIR/result

# number of repeats to estimate time and memory usage
# in each benchmarking task
NREP=3

# if PBS (Portable Batch System) / qsub is available
# in this system: 1 yes; 0 no
HAS_PBS=1

# queue name of PBS
PBS_QUEUE=cgsd


###### Check Global Variables
echo "[I::$cfg_prog] Check Global Variables ..."

echo "[I::$cfg_prog] PROJECT_DIR=$PROJECT_DIR"
echo "[I::$cfg_prog] ENV_NAME=$ENV_NAME"

if [ ! -d "$BIN_DIR" ]; then mkdir -p $BIN_DIR; fi
echo "[I::$cfg_prog] BIN_DIR=$BIN_DIR"

if [ ! -d "$DATA_DIR" ]; then mkdir -p $DATA_DIR; fi
echo "[I::$cfg_prog] DATA_DIR=$DATA_DIR"

if [ ! -d "$RES_DIR" ]; then mkdir -p $RES_DIR; fi
echo "[I::$cfg_prog] RES_DIR=$RES_DIR"

echo "[I::$cfg_prog] NREP=$NREP"

