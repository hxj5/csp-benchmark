#!/usr/bin/env Rscript
#Aim: to merge SNPs of two files based on CHROM+POS+REF+ALT.
#Note:
#  the input file should be either a tsv file which has four columns
#    <chrom> <pos> <ref> <alt>, or a vcf file

get_cols <- function(fn) {
  t1 <- read.table(fn, header = F, sep = "\t", comment.char = "#", nrows = 3)
  if (nrow(t1) < 1) { return(NULL) }
  nc <- ncol(t1)
  if (nc < 4) { return(NULL) }
  if (nc == 4) {  # a tsv file
    d1 <- read.table(fn, header = F, sep = "\t", comment.char = "#")
  } else {        # a vcf file
    col_class <- c("character", "integer", "NULL", "character", "character", rep("NULL", nc - 5))
    d1 <- read.table(fn, header = F, sep = "\t", comment.char = "#", colClasses = col_class)
  }
  colnames(d1) <- c("chrom", "pos", "ref", "alt")
  return(d1)
}

# parse command line args.
args <- commandArgs(trailingOnly = TRUE)
if (0 == length(args)) {
  print("use -h or --help for help on argument.")
  quit("no", 1)
}

library(argparse)
parser <- ArgumentParser(
  description = "", 
  formatter_class = "argparse.RawTextHelpFormatter"
)
parser$add_argument("-1", "--file1", type = "character", 
                    help = "The first file.")
parser$add_argument("-2", "--file2", type = "character", 
                    help = "The second file.")
parser$add_argument("-o", "--outfile", type = "character", 
                    help = "The merged file.")
args <- parser$parse_args()

# core part
d1 <- get_cols(args$file1)
d2 <- get_cols(args$file2)
dm <- merge(d1, d2, by = c("chrom", "pos", "ref", "alt"), 
            all = T, sort = T)  
write.table(dm, file = args$outfile, sep = "\t", quote = F, row.names = F, col.names = F, append = F)

